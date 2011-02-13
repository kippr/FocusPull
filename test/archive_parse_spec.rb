require 'focus'

describe FocusParser, "#parse" do

  before(:all) do
    @parser = FocusParser.new( "test", "omnisync-sample.tar", "tester" )
    @focus = @parser.parse
  end
  
  it "should read projects" do
    @focus.project("Spend less time in email").should_not be_nil
    @focus.projects.first.name.should_not be_nil
  end
  
  it "should parse project status" do
    @focus.project("iPad has open zone access").status.should == :dropped
    @focus.project("Spend less time in email").status.should == :active
    doneProject = @focus.project("Switch to 3 network")
    doneProject.status.should == :done
  end
  
  it "should parse start, modified, end dates" do
    doneProject = @focus.project("Switch to 3 network")
    doneProject.completed_date.should == Date.parse("2010-12-16")
    doneProject.created_date.should == Date.parse("2010-12-08")
    doneProject.updated_date.should == Date.parse("2010-12-16")
  end
  
  it "should read folders" do
    @focus.folder("Personal").should_not be_nil
    @focus.folders.detect("Admin").should_not be_nil
  end
  
  it "should build the folder tree structure" do
    planFolder = @focus.folder("Plan")
    planFolder.parent.name.should == "Secretive Project"
    @focus.folder("Secretive Project").children.should include(planFolder)
  end
  
  it "should build links from projects to folders" do
    @focus.project("Spend less time in email").parent.name.should == "Admin"
  end
  
  it "should link actions to their projects" do
    @focus.action("Collect useless mails in sd").parent.name.should == "Spend less time in email"
  end
  
  it "should build a tree starting with orphan nodes linked into root" do
    @focus.name.should == "Portfolio"
    @focus.parent.should be_nil
    personal = @focus.children.detect{ |c| c.name == "Personal" }
    personal.should_not be_nil
    personal.children.map( &:name ).should include( "Switch to 3 network" )   
  end
  
  it "should order folders and projects as per their rank" do
    pers_order =  rank_of_folder 'Personal'
    proj_order = rank_of_folder 'Secretive Project'
    adm_order = rank_of_folder 'Admin'
    #todo: is there a comparator expectation thingy?
    (adm_order < pers_order).should be_true
    (proj_order < adm_order).should be_true
  end
  
  def rank_of_folder name
    folder, order = @focus.folders.zip(1..100).detect{ | f, o | f.name == name }
    folder.should_not be_nil
    order  
  end

end
