# Get information about HDP
require 'facter'
require 'puppet'
require 'json'

Facter.add(:hdp_health) do
  confine kernel: 'Linux'
  out = {}
  setcode do
    if Dir.exist?('/opt/puppetlabs/hdp')
      begin
        image_data = {}
        cmd_output = Facter::Core::Execution.execute("docker ps --all --no-trunc --format '{{ json . }}'").split("\n")
        containers = []
        cmd_output.each do |json_hash|
          data = JSON.parse(json_hash)
          containers.push(data)
        end

        containers.each do |container|
          key = container['Names']
          value = {}
          next unless key.start_with?('hdp_')
          value['image'] = container['Image'].split(':')[0]
          value['tag'] = container['Image'].split(':')[1]
          data = Facter::Core::Execution.execute("docker inspect --format '{{ json .Image }}' #{key}")
          value['sha'] = JSON.parse(data).split(':')[1]
          image_data[key.to_s] = value
        end

        out['image_data'] = image_data
        out['puppet_user'] = Facter::Core::Execution.execute("bash -c \"stat -c '%G' /etc/puppetlabs/puppet/ssl/private_keys/#{Facter.value('fqdn')}.pem | xargs id -u\"").to_i
        out
      rescue
      end
    end
  end
end

Facter.add(:hdp) do
  setcode do
    require 'puppet'
    require 'puppet/indirector/resource/ral'
    require 'puppet/indirector/request'
    begin

      types = []
      Puppet::Type.loadall
      Puppet::Type.eachtype do |t|
        next if t.name == :component
        types << t.name.to_s
      end

      out = {}
      types.each { |type|
              begin
              res = {}
              raw = Puppet::Resource::Ral.indirection.search("#{type}/")
              raw.each { |r|
                    res[r.name] = r.parameters
              }
              out[type] = res
              rescue
              end
      }
      out
    rescue => err
       puts "#{err}"
    end
  end
end

