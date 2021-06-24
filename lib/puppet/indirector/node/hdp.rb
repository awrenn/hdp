require 'puppet/node'
require 'puppet/indirector/rest'
require 'puppet/util/puppetdb'

class Puppet::Node::Hdp < Puppet::Indirector::REST
  include Puppet::Util::Puppetdb

  def find(request)
  end

  def save(request)
  end

  def destroy(request)
  end
end
