require 'spec_helper'

describe ExperimentsController do
  let(:exp_active) { FactoryGirl.create(:experiment) }
  let(:exp_ended) { FactoryGirl.create(:ended_experiment) }

  describe "#set_experimental_path_names" do
    context "when base_resource_name is set to default" do
      before do
        @path_names = subject.experimental_path_names
      end

      it "sets the correct index path" do
        @path_names.index.should == '/experiments'
      end

      it "sets the correct new path" do
        @path_names.new.should == '/experiments/new'
      end

      it "sets the correct inactive path" do
        @path_names.inactive.should == '/experiments/inactive'
      end

      it "sets the correct set_winner path" do
        @path_names.set_winner.should == '/experiments/set_winner'
      end
    end
  end

  describe "#index" do
    it "should return OK" do
      get :index
      response.should be_ok
    end

    it "assign h1 correctly" do
      get :index
      assigns(:h1).should == "In-progress Experiments"
    end

    it "should set include_inactive to false" do
      get :index
      assigns(:include_inactive).should == false
    end

    it "should set experiments" do
      experiments = [exp_active]
      get :index
      assigns(:experiments).should == experiments
    end
  end

  describe "#inactive" do
    it "should return OK" do
      get :inactive
      response.should be_ok
    end

    it "assign h1 correctly" do
      get :inactive
      assigns(:h1).should == "Ended or Removed Experiments"
    end

    it "should set include_inactive to true" do
      get :inactive
      assigns(:include_inactive).should == true
    end

    it "should set experiments" do
      experiments = [exp_ended]
      get :inactive
      assigns(:experiments).should == experiments
    end
  end

  describe "#set_winner" do
    context "when the experiment exists" do
      let(:exp) { Experimental::Experiment.new }
      before do
        Experimental::Experiment.stub(find: exp)
      end

      def post_set_winner
        post :set_winner, id: 1, bucket_id: 0
      end

      context "when end is successful" do
        it "should return ok" do
          exp.should_receive(:end).and_return(true)
          post_set_winner
          response.should be_ok
        end
      end

      context "when end is not successful" do
        it "should return error" do
          exp.should_receive(:end).and_return(false)
          post_set_winner
          response.should be_error
        end
      end
    end

    context "when the experiment doesn't exist" do
      it "should return an error" do
        lambda { post :set_winner }.should raise_error
      end
    end
  end

  describe "GET #new" do
    it "returns a 200" do
      get :new
      response.should be_ok
    end

    it "assigns a new Experiment instance variable" do
      get :new
      assigns(:experiment).should be_kind_of(Experimental::Experiment)
    end

    it "renders the experiments/new template" do
      get :new
      response.should render_template(:new)
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        experimental_experiment: { name: "my awesome experiment", num_buckets: 2 }
      }
    end

    let(:invalid_params) do
      { experimental_experiment: {} }
    end

    context "when given valid name and num_buckets parameters" do
      it "creates a new experiment" do
        expect do
          post :create, valid_params
        end.to change(Experimental::Experiment, :count).by(1)
      end

      it "sets the start_date to the current time" do
        time = Time.now
        Time.stub(:now).and_return(time)

        exp = mock_model(Experimental::Experiment).as_null_object
        Experimental::Experiment.should_receive(:new).and_return(exp)
        exp.should_receive(:start_date=).with(time)

        post :create, valid_params
      end

      it "sets the admin flag" do
        time = Time.now
        Time.stub(:now).and_return(time)

        exp = mock_model(Experimental::Experiment).as_null_object
        Experimental::Experiment.should_receive(:new).and_return(exp)
        exp.should_receive(:admin=).with(true)

        post :create, valid_params
      end

      it "redirects to the index template" do
        post :create, valid_params
        response.should redirect_to(experiments_path)
      end

      it "displays a flash notification stating that it was created" do
        post :create, valid_params
        flash[:notice].should == "Experiment was successfully created."
      end
    end

    context "when not given valid parameters" do
      before do
        Experimental::Experiment.any_instance.should_receive(:save).and_return(false)
      end

      it "does not create an experiment" do
        expect do
          post :create, invalid_params
        end.to_not change(Experimental::Experiment, :count)
      end

      it "renders the new template" do
        post :create, invalid_params
        response.should render_template(:new)
      end

      it "displays a flash notification stating that there was an error" do
        post :create, invalid_params
        flash[:error].should == "There was an error!"
      end

      it "assigns the experiment instance variable" do
        post :create, invalid_params
        assigns(:experiment).should be_kind_of(Experimental::Experiment)
      end
    end
  end
end
