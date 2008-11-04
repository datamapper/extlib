require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe LazyArray do
  def self.it_should_return_self(method)
    it 'should delegate to the array and return self' do
      LazyArray::RETURN_SELF.should include(method)
    end
  end

  def self.it_should_return_plain(method)
    it 'should delegate to the array and return the results directly' do
      LazyArray::RETURN_SELF.should_not include(method)
    end
  end

  def self.it_should_not_be_a_kicker(method, *args, &block)
    it 'should not be a kicker method' do
      @lazy_array.send(method, *args, &block)
      @lazy_array.should_not be_loaded
    end
  end

  def self.it_should_be_a_kicker(method, *args, &block)
    it 'should not be a kicker method' do
      @lazy_array.send(method, *args, &block)
      @lazy_array.should be_loaded
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

  it 'should provide #at' do
    @lazy_array.should respond_to(:at)
  end

  describe '#at' do
    it_should_return_plain(:at)
    it_should_be_a_kicker(:at, 0)

    it 'should lookup the entry by index' do
      @lazy_array.at(0).should == @nancy
    end
  end

  it 'should provide #clear' do
    @lazy_array.should respond_to(:clear)
  end

  describe '#clear' do

    it 'should return self' do
      @lazy_array.clear.object_id.should == @lazy_array.object_id
    end

    it 'should make the lazy array become empty' do
      @lazy_array.clear.should be_empty
    end

    it 'should be loaded afterwards' do
      @lazy_array.should_not be_loaded
      cleared = @lazy_array.clear
      cleared.should be_loaded
    end
  end

  it 'should provide #collect!' do
    @lazy_array.should respond_to(:collect!)
  end

  describe '#collect!' do
    it_should_return_self(:collect!)
    it_should_be_a_kicker(:collect!) { |entry| entry }

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

  it 'should provide #concat' do
    @lazy_array.should respond_to(:concat)
  end

  describe '#concat' do
    it_should_return_self(:concat)
    it_should_be_a_kicker(:concat, [])

    it 'should return self' do
      @lazy_array.concat(@other).object_id.should == @lazy_array.object_id
    end

    it 'should concatenate another lazy array with #concat' do
      concatenated = @lazy_array.concat(@other)
      concatenated.should == [ @nancy, @bessie, @steve ]
    end
  end

  it 'should provide #delete' do
    @lazy_array.should respond_to(:delete)
  end

  describe '#delete' do
    it_should_return_plain(:delete)

    # Too bad, but this is needed because it needs to return the deleted element.
    it_should_be_a_kicker(:delete, nil)

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

  it 'should provide #delete_at' do
    @lazy_array.should respond_to(:delete_at)
  end

  describe '#delete_at' do
    it_should_return_plain(:delete_at)
    it_should_be_a_kicker(:delete_at, 0)

    it 'should delete the entry from the lazy array with the index' do
      @lazy_array.entries.should == [ @nancy, @bessie ]
      @lazy_array.delete_at(0).should == @nancy
      @lazy_array.entries.should == [ @bessie ]
    end
  end

  it 'should provide #delete_if' do
    @lazy_array.should respond_to(:delete_if)
  end

  describe '#delete_if' do

    it_should_not_be_a_kicker(:delete_if) {|e| true }

    it 'should return self if entries matched the block' do
      @lazy_array.delete_if { |entry| true }.object_id.should == @lazy_array.object_id
    end

    it 'should return self if no entries matched the block' do
      @lazy_array.delete_if { |entry| false }.object_id.should == @lazy_array.object_id
    end

    it 'should remove entries that matched the block' do
      @lazy_array.delete_if { |entry| true }
      @lazy_array.should be_empty
    end

    it 'should not remove entries that did not match the block' do
      @lazy_array.delete_if { |entry| false }
      @lazy_array.should == [ @nancy, @bessie ]
    end

  end

  it 'should provide #dup' do
    @lazy_array.should respond_to(:dup)
  end

  describe '#dup' do
    it_should_return_plain(:dup)

    it 'should dup the original array lazy' do
      dup = @lazy_array.dup
      dup.entries.should == @lazy_array.entries
    end

    it 'should dup a loaded array' do
      @lazy_array.each {|entry|}
      dup = @lazy_array.dup
      dup.entries.should == @lazy_array.entries
    end

    it 'should have the same load proc' do
      dup = @lazy_array.dup
      dup.to_proc.object_id.should == @lazy_array.to_proc.object_id
    end

  end

  it 'should provide #each' do
    @lazy_array.should respond_to(:each)
  end

  describe '#each' do
    it_should_return_self(:each)
    it_should_be_a_kicker(:each) {|e| true }

    it 'should return self' do
      @lazy_array.each { |entry| }.object_id.should == @lazy_array.object_id
    end

    it 'should iterate over the lazy array entries' do
      entries = []
      @lazy_array.each { |entry| entries << entry }
      entries.should == @lazy_array.entries
    end
  end

  it 'should provide #each_index' do
    @lazy_array.should respond_to(:each_index)
  end

  describe '#each_index' do
    it_should_return_self(:each_index)
    it_should_be_a_kicker(:each) {|e, i| true }

    it 'should return self' do
      @lazy_array.each_index { |entry| }.object_id.should == @lazy_array.object_id
    end

    it 'should iterate over the lazy array by index' do
      indexes = []
      @lazy_array.each_index { |index| indexes << index }
      indexes.should == [ 0, 1 ]
    end
  end

  it 'should provide #empty?' do
    @lazy_array.should respond_to(:empty?)
  end

  describe '#empty?' do
    it_should_return_plain(:empty?)
    it_should_be_a_kicker(:empty?)

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

  it 'should provide #entries' do
    @lazy_array.should respond_to(:entries)
  end

  describe '#entries' do
    it_should_return_plain(:entries)
    it_should_be_a_kicker(:entries)

    it 'should return an Array' do
      @lazy_array.entries.class.should == Array
    end
  end

  it 'should provide #freeze' do
    @lazy_array.should respond_to(:freeze)
  end

  describe '#freeze' do
    it_should_not_be_a_kicker(:freeze)

    it 'should freeze the underlying array' do
      @lazy_array.should_not be_frozen

      @lazy_array.freeze

      @lazy_array.should be_frozen
    end

    it 'should allow to be kicked even when frozen' do
      @lazy_array.freeze
      lambda { @lazy_array.each { |a| } }.should_not raise_error
    end

    it 'should not allow adding elements to a lazy frozen array' do
      @lazy_array.freeze
      lambda { @lazy_array << @nancy }.should raise_error
    end

    it 'should not allow adding elements to a loaded frozen array' do
      @lazy_array.each { |a| }
      @lazy_array.freeze
      lambda { @lazy_array << @nancy }.should raise_error
    end


  end

  it 'should provide #eql?' do
    @lazy_array.should respond_to(:eql?)
  end

  describe '#eql?' do
    it_should_return_plain(:eql?)
    it_should_be_a_kicker(:eql?, [])

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

  it 'should provide #fetch' do
    @lazy_array.should respond_to(:fetch)
  end

  describe '#fetch' do
    it_should_return_plain(:fetch)
    it_should_be_a_kicker(:fetch, 0)

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

  it 'should provide #first' do
    @lazy_array.should respond_to(:first)
  end

  describe '#first' do
    it_should_return_plain(:first)

    describe 'with no arguments' do
      it 'should return the first entry in the lazy array' do
        @lazy_array.first.should == @nancy
      end

      it 'should not load the lazy array if it is not needed' do
        @lazy_array.unshift(@bessie)
        @lazy_array.first.should == @bessie
        @lazy_array.should_not be_loaded
      end

    end

    describe 'with number of results specified' do
      it 'should return an Array ' do
        array = @lazy_array.first(2)
        array.class.should == Array
        array.should == [ @nancy, @bessie ]
      end

      it 'should load the lazy array if it is needed' do
        @lazy_array.unshift(@bessie)
        @lazy_array.first(2).should == [@bessie, @nancy]
        @lazy_array.should be_loaded
      end

    end
  end

  it 'should provide #index' do
    @lazy_array.should respond_to(:index)
  end

  describe '#index' do
    it_should_return_plain(:index)
    it_should_be_a_kicker(:index, nil)

    it 'should return an Integer' do
      @lazy_array.index(@nancy).should be_kind_of(Integer)
    end

    it 'should return the index for the first matching entry in the lazy array' do
      @lazy_array.index(@nancy).should == 0
    end
  end

  it 'should provide #insert' do
    @lazy_array.should respond_to(:insert)
  end

  describe '#insert' do
    it_should_return_self(:insert)

    it 'should return self' do
      @lazy_array.insert(1, @steve).object_id.should == @lazy_array.object_id
    end

    it 'should insert the entry at index in the lazy array' do
      @lazy_array.insert(1, @steve)
      @lazy_array.should == [ @nancy, @steve, @bessie ]
    end
  end

  it 'should provide #last' do
    @lazy_array.should respond_to(:last)
  end

  describe '#last' do
    it_should_return_plain(:last)

    describe 'with no arguments' do
      it 'should return the last entry in the lazy array and load if needed' do
        @lazy_array.last.should == @bessie
        @lazy_array.should be_loaded
      end

      it 'should return the last entry in the lazy array and not load if not needed' do
        @lazy_array << @nancy
        @lazy_array.last.should == @nancy
        @lazy_array.should_not be_loaded
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

  it 'should provide #length' do
    @lazy_array.should respond_to(:length)
  end

  describe '#length' do
    it_should_return_plain(:length)

    it 'should return an Integer' do
      @lazy_array.length.should be_kind_of(Integer)
    end

    it 'should return the length of the lazy array' do
      @lazy_array.length.should == 2
    end
  end

  it 'should provide #loaded?' do
    @lazy_array.should respond_to(:loaded?)
  end

  describe '#loaded?' do
    it 'should return true for an initialized lazy array' do
      @lazy_array.at(0)  # initialize the array
      @lazy_array.should be_loaded
    end

    it 'should return false for an uninitialized lazy array' do
      uninitialized = LazyArray.new
      uninitialized.should_not be_loaded
    end
  end

  it 'should provide #partition' do
    @lazy_array.should respond_to(:partition)
  end

  describe '#partition' do
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

  it 'should provide #pop' do
    @lazy_array.should respond_to(:pop)
  end

  describe '#pop' do
    it_should_return_plain(:pop)

    it 'should remove the last entry and load if needed' do
      @lazy_array.pop.should == @bessie
      @lazy_array.should be_loaded
      @lazy_array.should == [ @nancy ]
    end

    it 'should remove the last entry and not load if not needed' do
      @lazy_array << @nancy
      @lazy_array.pop.should == @nancy
      @lazy_array.should_not be_loaded
    end

  end

  it 'should provide #push' do
    @lazy_array.should respond_to(:push)
  end

  describe '#push' do

    it_should_not_be_a_kicker(:push, @steve)

    it 'should return self' do
      @lazy_array.push(@steve).object_id.should == @lazy_array.object_id
    end

    it 'should append an entry' do
      @lazy_array.push(@steve)
      @lazy_array.should == [ @nancy, @bessie, @steve ]
    end

  end

  it 'should provide #reject' do
    @lazy_array.should respond_to(:reject)
  end

  describe '#reject' do
    it_should_return_plain(:reject)

    # This could be changed in the future by creating
    # a new lazy array that has a pending block to
    # reject the necessary items
    it_should_be_a_kicker(:reject) { |entry| false }

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

  it 'should provide #reject!' do
    @lazy_array.should respond_to(:reject!)
  end

  describe '#reject!' do
    it_should_return_self(:reject!)

    # This must be a kicker because the return value identifies
    # whether it actually removed something or not, so the same
    # trick used for delete_if won't work here
    it_should_be_a_kicker(:reject!) { |entry| false }

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

  it 'should provide #replace' do
    @lazy_array.should respond_to(:replace)
  end

  describe '#replace' do

    it 'should return self' do
      @lazy_array.replace(@other).object_id.should == @lazy_array.object_id
    end

    it 'should replace itself with the other object' do
      replaced = @lazy_array.replace(@other)
      replaced.should == @other
    end

    it 'should be loaded afterwards' do
      @lazy_array.should_not be_loaded
      replaced = @lazy_array.replace(@other)
      replaced.should be_loaded
    end
  end

  it 'should provide #reverse' do
    @lazy_array.should respond_to(:reverse)
  end

  describe '#reverse' do
    it_should_return_plain(:reverse)
    it_should_be_a_kicker(:reverse)

    it 'should return an Array with reversed entries' do
      reversed = @lazy_array.reverse
      reversed.class.should == Array
      reversed.should == @lazy_array.entries.reverse
    end
  end

  it 'should provide #reverse!' do
    @lazy_array.should respond_to(:reverse!)
  end

  describe '#reverse!' do
    it_should_return_self(:reverse!)
    it_should_be_a_kicker(:reverse!)

    it 'should return self' do
      @lazy_array.reverse!.object_id.should == @lazy_array.object_id
    end

    it 'should reverse the order of entries in the lazy array inline' do
      entries = @lazy_array.entries
      @lazy_array.reverse!
      @lazy_array.entries.should == entries.reverse
    end
  end

  it 'should provide #reverse_each' do
    @lazy_array.should respond_to(:reverse_each)
  end

  describe '#reverse_each' do
    it_should_return_self(:reverse_each)
    it_should_be_a_kicker(:reverse_each) { |entry| }

    it 'should return self' do
      @lazy_array.reverse_each { |entry| }.object_id.should == @lazy_array.object_id
    end

    it 'should iterate through the lazy array in reverse' do
      entries = []
      @lazy_array.reverse_each { |entry| entries << entry }
      entries.should == @lazy_array.entries.reverse
    end
  end

  it 'should provide #rindex' do
    @lazy_array.should respond_to(:rindex)
  end

  describe '#rindex' do
    it_should_return_plain(:rindex)
    it_should_be_a_kicker(:rindex, nil)

    it 'should return an Integer' do
      @lazy_array.rindex(@nancy).should be_kind_of(Integer)
    end

    it 'should return the index for the last matching entry in the lazy array' do
      @lazy_array.rindex(@nancy).should == 0
    end
  end

  it 'should provide #select' do
    @lazy_array.should respond_to(:select)
  end

  describe '#select' do
    it_should_return_plain(:select)

    # This can also be optimized in the future by
    # using a pending block to delay actual selection
    it_should_be_a_kicker(:select) { |entry| true }

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

  it 'should provide #shift' do
    @lazy_array.should respond_to(:shift)
  end

  describe '#shift' do

    it_should_return_plain(:shift)

    it 'should remove the first entry and load if needed' do
      @lazy_array.shift.should == @nancy
      @lazy_array.should == [ @bessie ]
      @lazy_array.should be_loaded
    end

    it 'should remove the first entry and not load if not needed' do
      @lazy_array.unshift @bessie
      @lazy_array.shift.should == @bessie
      @lazy_array.should_not be_loaded
    end

  end

  it 'should provide #size' do
    @lazy_array.should respond_to(:size)
  end

  describe '#size' do
    it_should_return_plain(:size)
    it_should_be_a_kicker(:size)

    it 'should not modify the lazy array' do
      @lazy_array.size.should == 2
    end
  end

  it 'should provide #slice' do
    @lazy_array.should respond_to(:slice)
  end

  describe '#slice' do
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

  it 'should provide #slice!' do
    @lazy_array.should respond_to(:slice!)
  end

  describe '#slice!' do
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

  it 'should provide #sort' do
    @lazy_array.should respond_to(:sort)
  end

  describe '#sort' do
    it_should_return_plain(:sort)
    it_should_be_a_kicker(:sort)

    it 'should return an Array' do
      sorted = @lazy_array.sort { |a,b| a <=> b }
      sorted.class.should == Array
    end

    it 'should sort the entries' do
      sorted = @lazy_array.sort { |a,b| a <=> b }
      sorted.entries.should == @lazy_array.entries.reverse
    end
  end

  it 'should provide #sort!' do
    @lazy_array.should respond_to(:sort!)
  end

  describe '#sort!' do
    it_should_return_self(:sort!)
    it_should_be_a_kicker(:sort!)

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

  it 'should provide #to_a' do
    @lazy_array.should respond_to(:to_a)
  end

  describe '#to_a' do
    it_should_return_plain(:to_a)
    it_should_be_a_kicker(:to_a)

    it 'should return an Array' do
      @lazy_array.to_a.class.should == Array
    end
  end

  it 'should provide #to_ary' do
    @lazy_array.should respond_to(:to_ary)
  end

  describe '#to_ary' do
    it_should_return_plain(:to_ary)
    it_should_be_a_kicker(:to_ary)

    it 'should return an Array' do
      @lazy_array.to_ary.class.should == Array
    end
  end

  it 'should provide #to_proc' do
    @lazy_array.should respond_to(:to_proc)
  end

  describe '#to_proc' do

    it_should_not_be_a_kicker(:to_proc)

    it 'should return a Prox' do
      @lazy_array.to_proc.class.should == Proc
    end

    it 'should return the proc supplied to load_with' do
      proc = lambda { |a| }
      @lazy_array.load_with(&proc)
      @lazy_array.to_proc.object_id.should == proc.object_id
    end
  end

  it 'should provide #unload' do
    @lazy_array.should respond_to(:unload)
  end

  describe '#unload' do
    it 'should return self' do
      @lazy_array.unload.object_id.should == @lazy_array.object_id
    end

    it 'should make the lazy array become empty' do
      @lazy_array.should_not be_empty
      @lazy_array.load_with {}  # ensure it's not lazy-loaded by be_empty
      @lazy_array.unload.should be_empty
    end

    it 'should not be loaded afterwards' do
      @lazy_array.should_not be_loaded
      unloaded = @lazy_array.unload
      unloaded.should_not be_loaded
    end
  end

  it 'should provide #unshift' do
    @lazy_array.should respond_to(:unshift)
  end

  describe '#unshift' do

    it_should_not_be_a_kicker(:unshift, @steve)

    it 'should return self' do
      @lazy_array.unshift(@steve).object_id.should == @lazy_array.object_id
    end

    it 'should prepend an entry' do
      @lazy_array.unshift(@steve)
      @lazy_array.should == [ @steve, @nancy, @bessie ]
    end

  end

  it 'should provide #values_at' do
    @lazy_array.should respond_to(:values_at)
  end

  describe '#values_at' do
    it_should_return_plain(:values_at)
    it_should_be_a_kicker(:values_at, 0)

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
      module Enumerable
        def group_by(&block)
          groups = {}
          each do |entry|
            value = yield(entry)
            (groups[value] ||= []).push(entry)
          end
          groups
        end
      end
    end

    it 'should delegate to the Array' do
      @lazy_array.group_by { |e| e.length }.should == { 5 => %w[ nancy ], 6 => %w[ bessie ] }
    end
  end

  describe 'an unknown method' do
    it 'should raise an exception' do
      lambda { @lazy_array.unknown }.should raise_error(NoMethodError)
    end
  end
end
