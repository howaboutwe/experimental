require "spec_helper"

describe "experimental/_new" do
  let(:experiment) { FactoryGirl.build(:experiment) }

  before do
    assign(:experiment, experiment)
    controller.class.send(:include, Experimental::ControllerActions)
    assign(:experimental_path_names, controller.experimental_path_names)
  end

  it "renders a form for an experiment" do
    render
    rendered.should have_selector('form#new_experimental_experiment')
  end

  it "posts to the correct default path" do
    render
    rendered.should =~ /#{experiments_path}/
  end

  it "posts to the correct modified path" do
    paths = controller.experimental_path_names.dup.tap { |p| p.index = singles_admin_experiments_path }
    assign(:experimental_path_names, paths)

    render
    rendered.should =~ /#{singles_admin_experiments_path}/
  end

  it "renders a submit button" do
    render
    rendered.should have_selector('form#new_experimental_experiment input[type=submit]')
  end

  context "when the experiment has errors" do
    before do
      experiment.stub(:errors).
        and_return(mock(ActiveModel::Errors).as_null_object)
    end

    it "renders errors" do
      render
      rendered.should have_selector('form#new_experimental_experiment #error_explanation')
    end
  end
end
