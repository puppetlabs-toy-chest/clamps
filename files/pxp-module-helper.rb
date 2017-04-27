require 'net/http'
require 'openssl'
require 'json'
require 'securerandom'
require 'etc'
require 'socket'
require 'uri'

module Errors
  InvalidJson = "invalid_json"
  NoLastRunReport = "no_last_run_report"
end

DEFAULT_EXITCODE = -1

def metadata()
  return {
    :description => "PXP Puppet module",
    :actions => [
      { :name        => "run",
        :description => "Start a Puppet run",
        :input       => {
          :type      => "object",
          :properties => {
            :env => { :type => "array" },
            :flags => {
              :type => "array",
              :items => { :type => "string" }
            }
          },
          :required => [:flags]
        },
        :results => {
          :type => "object",
          :properties => {
            :kind => { :type => "string" },
            :time => { :type => "string" },
            :transaction_uuid => { :type => "string" },
            :environment => { :type => "string" },
            :status => { :type => "string" },
            :error_type => { :type => "string" },
            :error => { :type => "string" },
            :exitcode => { :type => "number" },
            :version => { :type => "number" }
          },
          :required => [:kind, :time, :transaction_uuid, :environment, :status,
                        :exitcode, :version]
        }
      }
    ],
    :configuration => {
      :type => "object",
      :properties => {
        :puppet_bin => { :type => "string" }
      }
    }
  }
end

def generate_facts(facts_cache, cert, config_path, id)
  facts = JSON.parse(File.read(facts_cache))
  facts['id'] = id
  facts['gid'] = id
  facts['identity']['user'] = id
  facts['identity']['group'] = id
  facts['clientcert'] = cert
  # TODO: other facts are also wrong. Is it worth loading Facter?
  {"name"=>cert,
   "values"=>facts,
   "timestamp"=>Time.now,
   "expiration"=>Time.now+30*60}
end

def generate_report(cert, config_version, transaction_uuid, catalog_uuid, code_id, environment, id)
  # TODO: generate resource_statuses from report
{"host"=>cert,
 "time"=>Time.now,
 "configuration_version"=>config_version,
 "transaction_uuid"=>transaction_uuid,
 "catalog_uuid"=>catalog_uuid,
 "code_id"=>code_id,
 "cached_catalog_status"=>"not_used",
 "report_format"=>6,
 "puppet_version"=>"4.10.0",
 "kind"=>"apply",
 "status"=>"unchanged",
 "noop"=>false,
 "noop_pending"=>false,
 "environment"=>environment,
 "master_used"=>nil,
 "logs"=>[
   ['info', "Using configured environment '#{environment}'"],
   ['info', 'Retrieving pluginfacts'],
   ['info', 'Retrieving plugins'],
   ['info', 'Loading facts'],
   ['info', "Caching catalog for #{cert}"],
   ['info', "Applying configuration version '#{config_version}'"],
   ['notice', "Applied catalog in 0.30 seconds"]
 ].map { |level, message|
   {"level"=>level,
    "message"=>message,
    "source"=>"Puppet",
    "tags"=>[level],
    "time"=>Time.now,
    "file"=>nil,
    "line"=>nil}
 },
 "metrics"=>
  {"resources"=>
    {"name"=>"resources",
     "label"=>"Resources",
     "values"=>
      [["total", "Total", 12],
       ["skipped", "Skipped", 0],
       ["failed", "Failed", 0],
       ["failed_to_restart", "Failed to restart", 0],
       ["restarted", "Restarted", 0],
       ["changed", "Changed", 0],
       ["out_of_sync", "Out of sync", 0],
       ["scheduled", "Scheduled", 0],
       ["corrective_change", "Corrective change", 0]]},
   "time"=>
    {"name"=>"time",
     "label"=>"Time",
     "values"=>
      [["filebucket", "Filebucket", 0.00021922100000000002],
       ["file", "File", 0.005378043],
       ["pe_anchor", "Pe anchor", 8.44e-05],
       ["schedule", "Schedule", 0.000322413],
       ["config_retrieval", "Config retrieval", 0.901037254],
       ["total", "Total", 0.9070413310000001]]},
   "changes"=>
    {"name"=>"changes", "label"=>"Changes", "values"=>[["total", "Total", 0]]},
   "events"=>
    {"name"=>"events",
     "label"=>"Events",
     "values"=>
      [["total", "Total", 0],
       ["failure", "Failure", 0],
       ["success", "Success", 0]]}},
 "resource_statuses"=>
  {"Filebucket[main]"=>
    {"title"=>"main",
     "file"=>"/etc/puppetlabs/code/environments/production/manifests/site.pp",
     "line"=>17,
     "resource"=>"Filebucket[main]",
     "resource_type"=>"Filebucket",
     "containment_path"=>["Stage[main]", "Main", "Filebucket[main]"],
     "evaluation_time"=>9.9716e-05,
     "tags"=>["filebucket", "main", "class"],
     "time"=>Time.now,
     "failed"=>false,
     "changed"=>false,
     "out_of_sync"=>false,
     "skipped"=>false,
     "change_count"=>0,
     "out_of_sync_count"=>0,
     "events"=>[],
     "corrective_change"=>false},
   "File[/home/#{id}/clamps_files/]"=>
    {"title"=>"/home/#{id}/clamps_files/",
     "file"=>
      "/etc/puppetlabs/code/environments/production/modules/clamps/manifests/init.pp",
     "line"=>6,
     "resource"=>"File[/home/#{id}/clamps_files/]",
     "resource_type"=>"File",
     "containment_path"=>
      ["Stage[main]", "Clamps", "File[/home/#{id}/clamps_files/]"],
     "evaluation_time"=>0.0019605,
     "tags"=>["file", "class", "clamps", "node", "default"],
     "time"=>Time.now,
     "failed"=>false,
     "changed"=>false,
     "out_of_sync"=>false,
     "skipped"=>false,
     "change_count"=>0,
     "out_of_sync_count"=>0,
     "events"=>[],
     "corrective_change"=>false},
   "File[/home/#{id}/clamps_files/static/]"=>
    {"title"=>"/home/#{id}/clamps_files/static/",
     "file"=>
      "/etc/puppetlabs/code/environments/production/modules/clamps/manifests/init.pp",
     "line"=>6,
     "resource"=>"File[/home/#{id}/clamps_files/static/]",
     "resource_type"=>"File",
     "containment_path"=>
      ["Stage[main]", "Clamps", "File[/home/#{id}/clamps_files/static/]"],
     "evaluation_time"=>0.001740802,
     "tags"=>["file", "class", "clamps", "node", "default"],
     "time"=>Time.now,
     "failed"=>false,
     "changed"=>false,
     "out_of_sync"=>false,
     "skipped"=>false,
     "change_count"=>0,
     "out_of_sync_count"=>0,
     "events"=>[],
     "corrective_change"=>false},
   "File[/home/#{id}/clamps_files/dynamic/]"=>
    {"title"=>"/home/#{id}/clamps_files/dynamic/",
     "file"=>
      "/etc/puppetlabs/code/environments/production/modules/clamps/manifests/init.pp",
     "line"=>6,
     "resource"=>"File[/home/#{id}/clamps_files/dynamic/]",
     "resource_type"=>"File",
     "containment_path"=>
      ["Stage[main]", "Clamps", "File[/home/#{id}/clamps_files/dynamic/]"],
     "evaluation_time"=>0.001676741,
     "tags"=>["file", "class", "clamps", "node", "default"],
     "time"=>Time.now,
     "failed"=>false,
     "changed"=>false,
     "out_of_sync"=>false,
     "skipped"=>false,
     "change_count"=>0,
     "out_of_sync_count"=>0,
     "events"=>[],
     "corrective_change"=>false},
   "Pe_anchor[puppet_enterprise:barrier:ca]"=>
    {"title"=>"puppet_enterprise:barrier:ca",
     "file"=>
      "/opt/puppetlabs/puppet/modules/puppet_enterprise/manifests/init.pp",
     "line"=>228,
     "resource"=>"Pe_anchor[puppet_enterprise:barrier:ca]",
     "resource_type"=>"Pe_anchor",
     "containment_path"=>
      ["Stage[main]",
       "Puppet_enterprise",
       "Pe_anchor[puppet_enterprise:barrier:ca]"],
     "evaluation_time"=>8.44e-05,
     "tags"=>
      ["pe_anchor",
       "puppet_enterprise:barrier:ca",
       "class",
       "puppet_enterprise",
       "node",
       "default"],
     "time"=>Time.now,
     "failed"=>false,
     "changed"=>false,
     "out_of_sync"=>false,
     "skipped"=>false,
     "change_count"=>0,
     "out_of_sync_count"=>0,
     "events"=>[],
     "corrective_change"=>false},
   "Schedule[puppet]"=>
    {"title"=>"puppet",
     "file"=>nil,
     "line"=>nil,
     "resource"=>"Schedule[puppet]",
     "resource_type"=>"Schedule",
     "containment_path"=>["Schedule[puppet]"],
     "evaluation_time"=>8.6252e-05,
     "tags"=>["schedule", "puppet"],
     "time"=>Time.now,
     "failed"=>false,
     "changed"=>false,
     "out_of_sync"=>false,
     "skipped"=>false,
     "change_count"=>0,
     "out_of_sync_count"=>0,
     "events"=>[],
     "corrective_change"=>false},
   "Schedule[hourly]"=>
    {"title"=>"hourly",
     "file"=>nil,
     "line"=>nil,
     "resource"=>"Schedule[hourly]",
     "resource_type"=>"Schedule",
     "containment_path"=>["Schedule[hourly]"],
     "evaluation_time"=>5.4082e-05,
     "tags"=>["schedule", "hourly"],
     "time"=>Time.now,
     "failed"=>false,
     "changed"=>false,
     "out_of_sync"=>false,
     "skipped"=>false,
     "change_count"=>0,
     "out_of_sync_count"=>0,
     "events"=>[],
     "corrective_change"=>false},
   "Schedule[daily]"=>
    {"title"=>"daily",
     "file"=>nil,
     "line"=>nil,
     "resource"=>"Schedule[daily]",
     "resource_type"=>"Schedule",
     "containment_path"=>["Schedule[daily]"],
     "evaluation_time"=>4.3e-05,
     "tags"=>["schedule", "daily"],
     "time"=>Time.now,
     "failed"=>false,
     "changed"=>false,
     "out_of_sync"=>false,
     "skipped"=>false,
     "change_count"=>0,
     "out_of_sync_count"=>0,
     "events"=>[],
     "corrective_change"=>false},
   "Schedule[weekly]"=>
    {"title"=>"weekly",
     "file"=>nil,
     "line"=>nil,
     "resource"=>"Schedule[weekly]",
     "resource_type"=>"Schedule",
     "containment_path"=>["Schedule[weekly]"],
     "evaluation_time"=>4.0858e-05,
     "tags"=>["schedule", "weekly"],
     "time"=>Time.now,
     "failed"=>false,
     "changed"=>false,
     "out_of_sync"=>false,
     "skipped"=>false,
     "change_count"=>0,
     "out_of_sync_count"=>0,
     "events"=>[],
     "corrective_change"=>false},
   "Schedule[monthly]"=>
    {"title"=>"monthly",
     "file"=>nil,
     "line"=>nil,
     "resource"=>"Schedule[monthly]",
     "resource_type"=>"Schedule",
     "containment_path"=>["Schedule[monthly]"],
     "evaluation_time"=>4.3853e-05,
     "tags"=>["schedule", "monthly"],
     "time"=>Time.now,
     "failed"=>false,
     "changed"=>false,
     "out_of_sync"=>false,
     "skipped"=>false,
     "change_count"=>0,
     "out_of_sync_count"=>0,
     "events"=>[],
     "corrective_change"=>false},
   "Schedule[never]"=>
    {"title"=>"never",
     "file"=>nil,
     "line"=>nil,
     "resource"=>"Schedule[never]",
     "resource_type"=>"Schedule",
     "containment_path"=>["Schedule[never]"],
     "evaluation_time"=>5.4368e-05,
     "tags"=>["schedule", "never"],
     "time"=>Time.now,
     "failed"=>false,
     "changed"=>false,
     "out_of_sync"=>false,
     "skipped"=>false,
     "change_count"=>0,
     "out_of_sync_count"=>0,
     "events"=>[],
     "corrective_change"=>false},
   "Filebucket[puppet]"=>
    {"title"=>"puppet",
     "file"=>nil,
     "line"=>nil,
     "resource"=>"Filebucket[puppet]",
     "resource_type"=>"Filebucket",
     "containment_path"=>["Filebucket[puppet]"],
     "evaluation_time"=>0.000119505,
     "tags"=>["filebucket", "puppet"],
     "time"=>Time.now,
     "failed"=>false,
     "changed"=>false,
     "out_of_sync"=>false,
     "skipped"=>false,
     "change_count"=>0,
     "out_of_sync_count"=>0,
     "events"=>[],
     "corrective_change"=>false}},
 "corrective_change"=>false}
end

def last_run_result(exitcode)
  return {"kind"             => "unknown",
          "time"             => "unknown",
          "transaction_uuid" => "unknown",
          "environment"      => "unknown",
          "status"           => "unknown",
          "exitcode"         => exitcode,
          "version"          => 1}
end

def make_error_result(exitcode, error_type, error_message)
  result = last_run_result(exitcode)
  result["error_type"] = error_type
  result["error"] = error_message
  return result
end

def configure_output(args)
  output_files = args["output_files"]
  if output_files
    begin
      $stdout.reopen(File.open(output_files["stdout"], 'w'))
      $stderr.reopen(File.open(output_files["stderr"], 'w'))
    rescue => e
      print make_error_result(DEFAULT_EXITCODE, Errors::InvalidJson,
                              "Could not open output files: #{e.message}").to_json
      exit 5 # this exit code is reserved for problems with opening of the output_files
    end

    at_exit do
      status = if $!.nil?
        0
      elsif $!.is_a?(SystemExit)
        $!.status
      else
        1
      end

      # flush the stdout/stderr before writing the exitcode
      # file to avoid pxp-agent reading incomplete output
      $stdout.fsync
      $stderr.fsync
      begin
        File.open(output_files["exitcode"], 'w') do |f|
          f.puts(status)
        end
      rescue => e
        print make_error_result(DEFAULT_EXITCODE, Errors::InvalidJson,
                                "Could not open exit code file: #{e.message}").to_json
        exit 5 # this exit code is reserved for problems with opening of the output_files
      end
    end
  end
end

def create_session(config_path, cert, host)
  session = Net::HTTP.new(host, 8140)

  session.ca_file = '/etc/puppetlabs/puppet/ssl/certs/ca.pem'
  ssl_path = File.join(config_path, 'etc', 'puppet', 'ssl')
  cert_path = File.join(ssl_path, 'certs', "#{cert}.pem")
  session.cert = OpenSSL::X509::Certificate.new(File.read(cert_path, :encoding => Encoding::ASCII))
  key_path = File.join(ssl_path, 'private_keys', "#{cert}.pem")
  session.key = OpenSSL::PKey::RSA.new(File.read(key_path, :encoding => Encoding::ASCII))

  session.verify_mode = OpenSSL::SSL::VERIFY_PEER
  session.use_ssl = true
  session.open_timeout = 120
  session.read_timeout = nil  # unlimited
  session
end

def run(use_cached_catalog, env, host, cert, config_path, id, facts_cache, sleep_interval)
  session = create_session(config_path, cert, host)
  tx_uuid = SecureRandom.uuid
  cache_path = File.join(config_path, 'opt', 'puppet.cache')

  catalog = nil
  if use_cached_catalog
    # Attempt to read the cached catalog
    begin
      catalog = JSON.parse(File.read(cache_path))
    rescue
      $stderr.puts "Unable to read cached catalog from #{cache_path}, performing full run"
    end
  end

  unless catalog
    # GET /puppet/v3/node/<cert>?environment=<env>&transaction_uuid=<uuid>&fail_on_404=true
    node_resp = session.get("/puppet/v3/node/#{cert}?environment=#{env}&transaction_uuid=#{tx_uuid}&fail_on_404=true")
    if node_resp.code != '200'
      return make_error_result(DEFAULT_EXITCODE, Errors::NoLastRunReport, "Puppet node request failed\n#{node_resp.body}")
    end

    begin
      node_data = JSON.parse(node_resp.body)
      # Use environment from node response
      env = node_data['environment']
    rescue
      return make_error_result(DEFAULT_EXITCODE, Errors::NoLastRunReport, "Puppet node response invalid\n#{node_resp.body}")
    end

    # GET /puppet/v3/file_metadatas/pluginfacts?environment=<env>&links=follow&recurse=true&source_permissions=use&ignore=.svn&ignore=CVS&ignore=.git&ignore=.hg&checksum_type=md5
    pluginfacts = session.get("/puppet/v3/file_metadatas/pluginfacts?environment=#{env}&links=follow&recurse=true&source_permissions=use&ignore=.svn&ignore=CVS&ignore=.git&ignore=.hg&checksum_type=md5")
    if pluginfacts.code != '200'
      return make_error_result(DEFAULT_EXITCODE, Errors::NoLastRunReport, "Puppet pluginfacts request failed\n#{pluginfacts.body}")
    end

    # GET /puppet/v3/file_metadatas/plugins?environment=<env>&links=follow&recurse=true&source_permissions=ignore&ignore=.svn&ignore=CVS&ignore=.git&ignore=.hg&checksum_type=md5
    pluginfacts = session.get("/puppet/v3/file_metadatas/plugins?environment=#{env}&links=follow&recurse=true&source_permissions=use&ignore=.svn&ignore=CVS&ignore=.git&ignore=.hg&checksum_type=md5")
    if pluginfacts.code != '200'
      return make_error_result(DEFAULT_EXITCODE, Errors::NoLastRunReport, "Puppet pluginfacts request failed\n#{pluginfacts.body}")
    end

    facts = generate_facts(facts_cache, cert, config_path, id)
    facts_body = "environment=#{env}&facts_format=pson&facts=#{URI.encode(facts.to_json)}&transaction_uuid=#{tx_uuid}&static_catalog=true&checksum_type=md5.sha256&fail_on_404=true"

    # POST /puppet/v3/catalog/<cert>?environment=<env> body=facts
    catalog_resp = session.post("/puppet/v3/catalog/#{cert}?environment=#{env}", facts_body)
    if catalog_resp.code != '200'
      return make_error_result(DEFAULT_EXITCODE, Errors::NoLastRunReport, "Puppet catalog request failed\n#{catalog_resp.body}")
    end

    begin
      catalog = JSON.parse(catalog_resp.body)
    rescue
      return make_error_result(DEFAULT_EXITCODE, Errors::NoLastRunReport, "Puppet catalog response invalid\n#{catalog_resp.body}")
    end

    # Cache catalog
    File.write(cache_path, catalog_resp.body)
  end

  sleep sleep_interval

  # PUT /puppet/v3/report/<cert>?environment=<env> body=report
  report = generate_report(cert, catalog['version'], tx_uuid, catalog['catalog_uuid'], catalog['code_id'], env, id)
  report_resp = session.put("/puppet/v3/report/#{cert}?environment=#{env}", report.to_json, 'Content-Type' => 'text/pson')
  if report_resp.code != '200'
    return make_error_result(DEFAULT_EXITCODE, Errors::NoLastRunReport, "Puppet report failed\n#{report_resp.body}")
  end

  result = last_run_result(0)
  result['kind'] = 'apply'
  result['time'] = Time.now
  result['transaction_uuid'] = tx_uuid
  result['environment'] = env
  result['status'] = 'unchanged'
  result
end
