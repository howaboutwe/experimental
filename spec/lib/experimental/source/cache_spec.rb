require 'spec_helper'

describe Experimental::Source::Cache do
  let(:original) { FactoryGirl.build(:experiment, name: 'e', notes: 'original') }
  let(:updated) { FactoryGirl.build(:experiment, name: 'e', notes: 'updated') }

  let(:inner) { Support::TestSource.new }
  let(:source) { Experimental::Source::Cache.new(inner) }

  before { Timecop.freeze(Time.utc(2001, 2, 3, 4, 5, 6)) }
  after { Timecop.return }

  describe "#[]" do
    before { inner.add(original) }

    context "on a cold cache" do
      it "returns the named experiment from the source" do
        source['e'].should == original
      end

      it "accepts a symbol for the experiment name" do
        source[:e].should == original
      end
    end

    context "when experiments are cached" do
      before do
        source.available
        inner.add(updated)
      end

      it "returns the cached experiment" do
        source['e'].should == original
      end

      context "when the TTL has expired" do
        let(:source) { Experimental::Source::Cache.new(inner, ttl: 300) }
        before { Timecop.freeze(Time.now + 301) }

        it "fetches experiments from the source and returns the named experiment" do
          source['e'].should == updated
        end
      end
    end
  end

  describe "#available" do
    before { inner.add(original) }

    context "on a cold cache" do
      it "returns the experiment from the source" do
        source.available.should == [original]
      end
    end

    context "when experiments are cached" do
      before do
        source.available
        inner.add(updated)
      end

      it "returns the cached available experiments" do
        source.available.should == [original]
      end

      context "when the TTL has expired" do
        let(:source) { Experimental::Source::Cache.new(inner, ttl: 300) }
        before { Timecop.freeze(Time.now + 301) }

        it "fetches and returns experiments from the source" do
          source.available.should == [updated]
        end
      end
    end
  end
end
