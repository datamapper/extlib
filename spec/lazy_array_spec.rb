require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe LazyArray do
  def self.describe_method(method, &block)
    it "should provide ##{method}" do
      @lazy_array.should respond_to(method)
    end

    describe("##{method}") { yield }
  end

  def self.it_should_return_self(method)
    it 'should delegate to the array and return self' do
      LazyArray::RETURN_SELF.should include(method)
    end
  end

  def self.it_should_return_plain(method)
    it 'should delegate to the array and return the results directly' do
      LazyArray::RETURN_PLAIN.should include(method)
    end
  end

  before do
    @nancy  = 'nancy'
    @bessie = 'bessie'
    @steve  = 'steve'

    @lazy_array = LazyArray.new
    @lazy_array.load_with { |la| la.push(@nancy, @bessie) }

    @other = LazyArray.new
    @other.load_with { |la| la.push(@steve) }
  end

  describe_method(:at) do
    it_should_return_plain(:at)

    it 'should lookup the entry by index' do
      @lazy_array.at(0).should == @nancy
    end
  end

  describe_method(:clear) do
    it_should_return_self(:clear)

    it 'should return self' do
      @lazy_array.clear.object_id.should == @lazy_array.object_id
    end

    it 'should make the lazy array become empty' do
      @lazy_array.clear.should be_empty
    end

    it 'should be loaded afterwards' do
      @lazy_array.should_not be_loaded
      @lazy_array.should_not_receive(:lazy_load!)

      cleared = @lazy_array.clear
      cleared.should be_loaded
    end
  end

  describe_method(:collect!) do
    it_should_return_self(:collect!)

    it 'should return self' do
      @lazy_array.collect! { |entry| entry }.object_id.should == @lazy_array.object_id
    end

    it 'should iterate over the lazy array' do
      entries = []
      @lazy_array.collect! { |entry| entries << entry; entry }
      entries.should == @lazy_array.entries
    end

    it 'should update the lazy array with the result of the block' do
      @lazy_array.collect! { |entry| @steve }.entries.should == [ @steve, @steve ]
    end
  end

  describe_method(:concat) do
    it_should_return_self(:concat)

    it 'should return self' do
      @lazy_array.concat(@other).object_id.should == @lazy_array.object_id
    end

    it 'should concatenate another lazy array with #concat' do
      concatenated = @lazy_array.concat(@other)
      concatenated.should == [ @nancy, @bessie, @steve ]
    end
  end

  describe_method(:delete) do
    it_should_return_plain(:delete)

    it 'should delete the matching entry from the lazy array' do
      @lazy_array.entries.should == [ @nancy, @bessie ]
      @lazy_array.delete(@nancy).should == @nancy
      @lazy_array.entries.should == [ @bessie ]
    end

    it 'should use the passed-in block when no entry was removed' do
      @lazy_array.entries.should == [ @nancy, @bessie ]
      @lazy_array.delete(@steve) { @steve }.should == @steve
      @lazy_array.entries.should == [ @nancy, @bessie ]
    end
  end

  describe_method(:delete_at) do
    it_should_return_plain(:delete_at)

    it 'should delete the entry from the lazy array with the index' do
      @lazy_array.entries.should == [ @nancy, @bessie ]
      @lazy_array.delete_at(0).should == @nancy
      @lazy_array.entries.should == [ @bessie ]
    end
  end

  describe_method(:each) do
    it_should_return_self(:each)

    it 'should return self' do
      @lazy_array.each { |entry| }.object_id.should == @lazy_array.object_id
    end

    it 'should iterate over the lazy array entries' do
      entries = []
      @lazy_array.each { |entry| entries << entry }
      entries.should == @lazy_array.entries
    end
  end

  describe_method(:each_index) do
    it_should_return_self(:each_index)

    it 'should return self' do
      @lazy_array.each_index { |entry| }.object_id.should == @lazy_array.object_id
    end

    it 'should iterate over the lazy array by index' do
      indexes = []
      @lazy_array.each_index { |index| indexes << index }
      indexes.should == [ 0, 1 ]
    end
  end

  describe_method(:empty?) do
    it_should_return_plain(:empty?)

    it 'should return true if the lazy array has entries' do
      @lazy_array.length.should == 2
      @lazy_array.empty?.should be_false
    end

    it 'should return false if the lazy array has no entries' do
      @lazy_array.clear
      @lazy_array.length.should == 0
      @lazy_array.empty?.should be_true
    end
  end

  describe_method(:entries) do
    it_should_return_plain(:entries)

    it 'should return an Array' do
      @lazy_array.entries.class.should == Array
    end
  end

  describe_method(:eql?) do
    it 'should return true if for the same lazy array' do
      @lazy_array.object_id.should == @lazy_array.object_id
      @lazy_array.entries.should == @lazy_array.entries
      @lazy_array.should be_eql(@lazy_array)
    end

    it 'should return true for duplicate lazy arrays' do
      dup = @lazy_array.dup
      dup.should be_kind_of(LazyArray)
      dup.object_id.should_not == @lazy_array.object_id
      dup.should be_eql(@lazy_array)
    end

    it 'should return false for different lazy arrays' do
      @lazy_array.should_not be_eql(@other)
    end
  end

  describe_method(:fetch) do
    it_should_return_plain(:fetch)

    it 'should lookup the entry with an index' do
      @lazy_array.fetch(0).should == @nancy
    end

    it 'should throw an IndexError exception if the index is outside the array' do
      lambda { @lazy_array.fetch(99) }.should raise_error(IndexError)
    end

    it 'should substitute the default if the index is outside the array' do
      entry = 'cow'
      @lazy_array.fetch(99, entry).object_id.should == entry.object_id
    end

    it 'should substitute the value returned by the default block if the index is outside the array' do
      entry = 'cow'
      @lazy_array.fetch(99) { entry }.object_id.should == entry.object_id
    end
  end

  describe_method(:first) do
    it_should_return_plain(:first)

    describe 'with no arguments' do
      it 'should return the first entry in the lazy array' do
        @lazy_array.first.should == @nancy
      end
    end

    describe 'with number of results specified' do
      it 'should return an Array ' do
        array = @lazy_array.first(2)
        array.class.should == Array
        array.should == [ @nancy, @bessie ]
      end
    end
  end

  describe_method(:index) do
    it_should_return_plain(:index)

    it 'should return an Integer' do
      @lazy_array.index(@nancy).should be_kind_of(Integer)
    end

    it 'should return the index for the first matching entry in the lazy array' do
      @lazy_array.index(@nancy).should == 0
    end
  end

  describe_method(:insert) do
    it_should_return_self(:insert)

    it 'should return self' do
      @lazy_array.insert(1, @steve).object_id.should == @lazy_array.object_id
    end

    it 'should insert the entry at index in the lazy array' do
      @lazy_array.insert(1, @steve)
      @lazy_array.should == [ @nancy, @steve, @bessie ]
    end
  end

  describe_method(:last) do
    it_should_return_plain(:last)

    describe 'with no arguments' do
      it 'should return the last entry in the lazy array' do
        @lazy_array.last.should == @bessie
      end
    end

    describe 'with number of results specified' do
      it 'should return an Array' do
        array = @lazy_array.last(2)
        array.class.should == Array
        array.should == [ @nancy, @bessie ]
      end
    end
  end

  describe_method(:length) do
    it_should_return_plain(:length)

    it 'should return an Integer' do
      @lazy_array.length.should be_kind_of(Integer)
    end

    it 'should return the length of the lazy array' do
      @lazy_array.length.should == 2
    end
  end

  describe_method(:loaded?) do
    it 'should return true for an initialized lazy array' do
      @lazy_array.at(0)  # initialize the array
      @lazy_array.should be_loaded
    end

    it 'should return false for an uninitialized lazy array' do
      uninitialized = LazyArray.new
      uninitialized.should_not be_loaded
    end
  end

  describe_method(:partition) do
    describe 'return value' do
      before do
        @array = @lazy_array.partition { |e| e == @nancy }
      end

      it 'should be an Array' do
        @array.should be_kind_of(Array)
      end

      it 'should have two entries' do
        @array.length.should == 2
      end

      describe 'first entry' do
        before do
          @true_results = @array.first
        end

        it 'should be an Array' do
          @true_results.class.should == Array
        end

        it 'should have one entry' do
          @true_results.length.should == 1
        end

        it 'should contain the entry the block returned true for' do
          @true_results.should == [ @nancy ]
        end
      end

      describe 'second entry' do
        before do
          @false_results = @array.last
        end

        it 'should be an Array' do
          @false_results.class.should == Array
        end

        it 'should have one entry' do
          @false_results.length.should == 1
        end

        it 'should contain the entry the block returned true for' do
          @false_results.should == [ @bessie ]
        end
      end
    end
  end

  describe_method(:pop) do
    it_should_return_plain(:pop)

    it 'should remove the last entry' do
      @lazy_array.pop.should == @bessie
      @lazy_array.should == [ @nancy ]
    end
  end

  describe_method(:push) do
    it_should_return_self(:push)

    it 'should return self' do
      @lazy_array.push(@steve).object_id.should == @lazy_array.object_id
    end

    it 'should append an entry' do
      @lazy_array.push(@steve)
      @lazy_array.should == [ @nancy, @bessie, @steve ]
    end
  end

  describe_method(:reject) do
    it_should_return_plain(:reject)

    it 'should return an Array with entries that did not match the block' do
      rejected = @lazy_array.reject { |entry| false }
      rejected.class.should == Array
      rejected.should == [ @nancy, @bessie ]
    end

    it 'should return an empty Array if entries matched the block' do
      rejected = @lazy_array.reject { |entry| true }
      rejected.class.should == Array
      rejected.should == []
    end
  end

  describe_method(:reject!) do
    it_should_return_self(:reject!)

    it 'should return self if entries matched the block' do
      @lazy_array.reject! { |entry| true }.object_id.should == @lazy_array.object_id
    end

    it 'should return nil if no entries matched the block' do
      @lazy_array.reject! { |entry| false }.should be_nil
    end

    it 'should remove entries that matched the block' do
      @lazy_array.reject! { |entry| true }
      @lazy_array.should be_empty
    end

    it 'should not remove entries that did not match the block' do
      @lazy_array.reject! { |entry| false }
      @lazy_array.should == [ @nancy, @bessie ]
    end
  end

  describe_method(:replace) do
    it_should_return_self(:replace)

    it 'should return self' do
      @lazy_array.replace(@other).object_id.should == @lazy_array.object_id
    end

    it 'should replace itself with the other object' do
      replaced = @lazy_array.replace(@other)
      replaced.should == @other
    end

    it 'should be loaded afterwards' do
      @lazy_array.should_not be_loaded
      @lazy_array.should_not_receive(:lazy_load!)

      replaced = @lazy_array.replace(@other)
      replaced.should be_loaded
    end
  end

  describe_method(:reverse) do
    it_should_return_plain(:reverse)

    it 'should return an Array with reversed entries' do
      reversed = @lazy_array.reverse
      reversed.class.should == Array
      reversed.should == @lazy_array.entries.reverse
    end
  end

  describe_method(:reverse!) do
    it_should_return_self(:reverse!)

    it 'should return self' do
      @lazy_array.reverse!.object_id.should == @lazy_array.object_id
    end

    it 'should reverse the order of entries in the lazy array inline' do
      entries = @lazy_array.entries
      @lazy_array.reverse!
      @lazy_array.entries.should == entries.reverse
    end
  end

  describe_method(:reverse_each) do
    it_should_return_self(:reverse_each)

    it 'should return self' do
      @lazy_array.reverse_each { |entry| }.object_id.should == @lazy_array.object_id
    end

    it 'should iterate through the lazy array in reverse' do
      entries = []
      @lazy_array.reverse_each { |entry| entries << entry }
      entries.should == @lazy_array.entries.reverse
    end
  end

  describe_method(:rindex) do
    it_should_return_plain(:rindex)

    it 'should return an Integer' do
      @lazy_array.rindex(@nancy).should be_kind_of(Integer)
    end

    it 'should return the index for the last matching entry in the lazy array' do
      @lazy_array.rindex(@nancy).should == 0
    end
  end

  describe_method(:select) do
    it_should_return_plain(:select)

    it 'should return an Array with entries that matched the block' do
      selected = @lazy_array.select { |entry| true }
      selected.class.should == Array
      selected.should == @lazy_array.entries
    end

    it 'should return an empty Array if no entries matched the block' do
      selected = @lazy_array.select { |entry| false }
      selected.class.should == Array
      selected.should be_empty
    end
  end

  describe_method(:shift) do
    it_should_return_plain(:shift)

    it 'should remove the first entry' do
      @lazy_array.shift.should == @nancy
      @lazy_array.should == [ @bessie ]
    end
  end

  describe_method(:slice) do
    it_should_return_plain(:slice)

    describe 'with an index' do
      it 'should not modify the lazy array' do
        @lazy_array.slice(0)
        @lazy_array.size.should == 2
      end
    end

    describe 'with a start and length' do
      it 'should return an Array' do
        sliced = @lazy_array.slice(0, 1)
        sliced.class.should == Array
        sliced.should == [ @nancy ]
      end

      it 'should not modify the lazy array' do
        @lazy_array.slice(0, 1)
        @lazy_array.size.should == 2
      end
    end

    describe 'with a Range' do
      it 'should return an Array' do
        sliced = @lazy_array.slice(0..1)
        sliced.class.should == Array
        sliced.should == [ @nancy, @bessie ]
      end

      it 'should not modify the lazy array' do
        @lazy_array.slice(0..1)
        @lazy_array.size.should == 2
      end
    end
  end

  describe_method(:slice!) do
    it_should_return_plain(:slice!)

    describe 'with an index' do
      it 'should modify the lazy array' do
        @lazy_array.slice!(0)
        @lazy_array.size.should == 1
      end
    end

    describe 'with a start and length' do
      it 'should return an Array' do
        sliced = @lazy_array.slice!(0, 1)
        sliced.class.should == Array
        sliced.should == [ @nancy ]
      end

      it 'should modify the lazy array' do
        @lazy_array.slice!(0, 1)
        @lazy_array.size.should == 1
      end
    end

    describe 'with a Range' do
      it 'should return an Array' do
        sliced = @lazy_array.slice(0..1)
        sliced.class.should == Array
        sliced.should == [ @nancy, @bessie ]
      end

      it 'should modify the lazy array' do
        @lazy_array.slice!(0..1)
        @lazy_array.size.should == 0
      end
    end
  end

  describe_method(:sort) do
    it_should_return_plain(:sort)

    it 'should return an Array' do
      sorted = @lazy_array.sort { |a,b| a <=> b }
      sorted.class.should == Array
    end

    it 'should sort the entries' do
      sorted = @lazy_array.sort { |a,b| a <=> b }
      sorted.entries.should == @lazy_array.entries.reverse
    end
  end

  describe_method(:sort!) do
    it_should_return_self(:sort!)

    it 'should return self' do
      @lazy_array.sort! { |a,b| 0 }.object_id.should == @lazy_array.object_id
    end

    it 'should sort the LazyArray in place' do
      original_entries = @lazy_array.entries
      @lazy_array.length.should == 2
      @lazy_array.sort! { |a,b| a <=> b }
      @lazy_array.length.should == 2
      @lazy_array.entries.should == original_entries.reverse
    end
  end

  describe_method(:to_a) do
    it_should_return_plain(:to_a)

    it 'should return an Array' do
      @lazy_array.to_a.class.should == Array
    end
  end

  describe_method(:to_ary) do
    it_should_return_plain(:to_ary)

    it 'should return an Array' do
      @lazy_array.to_ary.class.should == Array
    end
  end

  describe_method(:unshift) do
    it_should_return_self(:unshift)

    it 'should return self' do
      @lazy_array.unshift(@steve).object_id.should == @lazy_array.object_id
    end

    it 'should prepend an entry' do
      @lazy_array.unshift(@steve)
      @lazy_array.should == [ @steve, @nancy, @bessie ]
    end
  end

  describe_method(:values_at) do
    it_should_return_plain(:values_at)

    it 'should return an Array' do
      values = @lazy_array.values_at(0)
      values.class.should == Array
    end

    it 'should return an Array of the entries at the index' do
      @lazy_array.values_at(0).entries.should == [ @nancy ]
    end
  end

  describe 'a method mixed into Array' do
    before :all do
      class Array
        def group_by(&block)
          groups = []
          each do |entry|
            value = yield(entry)
            if(last_group = groups.last) && last_group.first == value
              last_group.last << entry
            else
              groups << [ value, [ entry ] ]
            end
          end
          groups
        end
      end
    end

    it 'should delegate to the Array' do
      @lazy_array.group_by { |e| e.length }.should == [ [ 5, %w[ nancy ] ], [ 6, %w[ bessie ] ] ]
    end
  end

  describe 'an unknown method' do
    it 'should raise an exception' do
      lambda { @lazy_array.unknown }.should raise_error(NoMethodError)
    end
  end
end
