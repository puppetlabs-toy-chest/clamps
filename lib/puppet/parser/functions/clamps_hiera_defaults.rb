#!/opt/puppet/bin/ruby
require 'puppet/face'
require 'yaml'

module Puppet::Parser::Functions
  newfunction(:clamps_hiera_defaults, :type => :rvalue, :arity => 0, :doc => <<-EOS
  This function reads through the modules on disk via the resource_type face
  It then determines the parameters for these classes and their defaults.
  It creates hiera data binding compatible key names i.e. 'apache::user'
  and the evaluated ruby object as the value. This preserves boolean/hash/array 
  EOS
) do |args|

  #Puppet.parse_config
  environment = Puppet[:environment] || 'production'
  resources = Puppet::Face[:resource_type, '0.0.1'].search('.*',{:extra => { 'environment' => environment }})

  response = Hash.new
    resources.each do |resource|
     resource.arguments.each do |k,v|
        # Walk the AST types and evaluate them, Puppet 4 may need updates
        case v.class.to_s
          when "Puppet::Parser::AST::String"
            result = v.evaluate('subscope')
          when "Puppet::Parser::AST::Undef"
            # "We don't want undef values..."
            next
          #when "Puppet::Parser::AST::Variable"
          #  # Remove the $ in the name and wrap in hiera
          #  # inpolation to defer the lookup until runtime
          #  result = "%{#{v.to_s[1..-1]}}"
          when "Puppet::Parser::AST::ASTHash"
            result = v.evaluate('subscope')
            break if result.empty?
          when "Puppet::Parser::AST::ASTArray"
            result = v.evaluate('subscope')
          when "Puppet::Parser::AST::Boolean"
            result = v.evaluate('subscope')
          else
            # "We don't want raw puppet code like functions..."
            next
          end
        # This should generate keys like "class::param": "value"
        # eyaml auto quotes anything with a colon in the string
        response["#{resource.name}::#{k.to_s}"] = result
      end
    end
    response
  end
end
