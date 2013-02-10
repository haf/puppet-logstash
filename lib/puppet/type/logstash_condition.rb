Puppet::Type.newtype(:logstash_condition) do


  @doc = ""

  newparam(:name, :namevar => true) do
    desc "Unique name"
  end

  newparam(:condition) do
    desc "Condition"
  end

  newparam(:expression) do
    desc "Expression"
  end

  newparam(:childeren) do
    desc "Childeren items"
  end

  newparam(:order) do
    desc "Order"
    defaultto '10'
    validate do |val|
      fail Puppet::ParseError, "only integers > 0 are allowed and not '#{val}'" if val !~ /^\d+$/
    end
  end

  newparam(:tag) do
    desc "Tag"
  end

  validate do
    # think up some validation
  end

end
