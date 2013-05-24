# encoding: UTF-8

require 'spec_helper'

describe Pom do
  let(:pom) { Pom.new(File.join("spec", "data", "commons-logging", "pom.xml")) }
  
  describe "#connection_address" do
    it "reads the SCM connection address" do
      pom.connection_address.should eq "svn:http://svn.apache.org/repos/asf/commons/proper/logging/tags/commons-logging-1.1.1"
    end
  end
  
  describe "#group_id" do
    it "reads the group id" do
      pom.group_id.should eq "commons-logging"
    end
  end

  describe "#artifact_id" do
    it "reads the artifact id" do
      pom.artifact_id.should eq "commons-logging"
    end
  end
end
