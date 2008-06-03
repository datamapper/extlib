require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe Extlib::Inflection do

  it 'should pluralize a word' do
    'car'.plural.should == 'cars'
    Extlib::Inflection.pluralize('car').should == 'cars'
  end

  it 'should singularize a word' do
    "cars".singular.should == "car"
    Extlib::Inflection.singularize('cars').should == 'car'
  end

  it 'should classify an underscored name' do
    Extlib::Inflection.classify('data_mapper').should == 'DataMapper'
  end

  it 'should camelize an underscored name' do
    Extlib::Inflection.camelize('data_mapper').should == 'DataMapper'
  end

  it 'should underscore a camelized name' do
    Extlib::Inflection.underscore('DataMapper').should == 'data_mapper'
  end

  it 'should humanize names' do
    Extlib::Inflection.humanize('employee_salary').should == 'Employee salary'
    Extlib::Inflection.humanize('author_id').should == 'Author'
  end

  it 'should demodulize a module name' do
    Extlib::Inflection.demodulize('DataMapper::Inflector').should == 'Inflector'
  end

  it 'should tableize a name (underscore with last word plural)' do
    Extlib::Inflection.tableize('fancy_category').should == 'fancy_categories'
    Extlib::Inflection.tableize('FancyCategory').should == 'fancy_categories'
  end

  it 'should create a fk name from a class name' do
    Extlib::Inflection.foreign_key('Message').should == 'message_id'
    Extlib::Inflection.foreign_key('Admin::Post').should == 'post_id'
  end





end
