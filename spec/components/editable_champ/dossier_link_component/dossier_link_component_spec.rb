RSpec.describe EditableChamp::DossierLinkComponent, type: :component do
  # Define a mock form object
  let(:form) { instance_double('Form') }

  # Create a user for the context
  let(:current_user) { create(:user) }

  # Create a procedure with a public dossier link type
  let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :dossier_link}]) }

  # Create a dossier in 'en_construction' state associated with the current user and procedure
  let(:dossier) { create(:dossier, :en_construction, user: current_user, depose_at: Time.zone.now, procedure: procedure) }

  # Get the first champ from the dossier
  let(:champ) { dossier.champs.first }

  # Define a list of procedures with different states
  let(:procedures) do
    [
      create(:procedure, id: 1, libelle: "Procedure 1", aasm_state: "publiee"),
      create(:procedure, id: 2, libelle: "Procedure 2", aasm_state: "brouillon"),
      create(:procedure, id: 3, libelle: "Procedure 3", aasm_state: "close")
    ]
  end

  # Define a list of procedures not included in the limitation
  let(:procedures_no_in_the_limitation) do
    [
      create(:procedure, id: 4, libelle: "Procedure 4 - pas dans la limitation", aasm_state: "publiee"),
      create(:procedure, id: 5, libelle: "Procedure 5 - pas dans la limitation", aasm_state: "publiee"),
    ]
  end

  # Helper method to create multiple dossiers with specified status and procedure
  def create_dossiers(number, status, procedure_limited, hidden_by_user_at = nil)
    Array.new(number) do
      create(:dossier, status, user: current_user, depose_at: Time.zone.now, procedure: procedure_limited, hidden_by_user_at: hidden_by_user_at)
    end
  end

  # Helper method to generate the "no dossier" option for a given procedure ID
  def no_dossier_option(procedure_id)
    {
      label: "Vous n’avez déposé aucun dossier sur cette démarche. ",
      value: "no_dossier_#{procedure_id}"
    }
  end

  # Helper method to generate the dossier option for a given dossier
  def dossier_option(dossier)
    {
      label: "N° #{dossier.id} - déposé le #{dossier.depose_at.strftime('%d/%m/%Y')}",
      value: dossier.id.to_s
    }
  end

  # Helper method to generate the procedure separator option for a given procedure
  def procedure_separator_option(procedure)
    {
      label: "-- Démarche : #{procedure.libelle} --",
      value: "separator_#{procedure.id}"
    }
  end

  # Setup before each test
  before do
    allow_any_instance_of(described_class).to receive(:current_user).and_return(current_user)
    procedure.active_revision.types_de_champ.first.procedures = procedures
  end

  # Define the subject for the tests
  subject { described_class.new(form: form, champ: champ) }

  # Test for the dsfr_input_classname method
  describe '#dsfr_input_classname' do
    it 'returns the class name for the input element' do
      expect(subject.send(:dsfr_input_classname)).to eq('fr-input')
    end
  end

  # Test for the dossier_options_for method
  describe '#dossier_options_for' do
    # Create a dossier in 'en_construction' state for the first procedure
    let(:dossiers_en_construction) { create_dossiers(1, :en_construction, procedures[0]) }

    it 'returns the options for dossier selection' do
      procedures[0].dossiers = dossiers_en_construction
      subject.send(:before_render)

      # Get the dossier options
      options = subject.send(:dossier_options_for, champ)

      # Verify the options include specific labels and values
      expect(options).to include(procedure_separator_option(procedures[0]))
      expect(options).to include(dossier_option(dossiers_en_construction[0]))
      expect(options).to include(procedure_separator_option(procedures[1]))
      expect(options).to include(no_dossier_option(2))
      expect(options).to include(procedure_separator_option(procedures[2]))
      expect(options).to include(no_dossier_option(3))
    end
  end

  # Test for the react_props method
  describe '#react_props' do
    it 'returns the props for the React component' do
      # Set the champ value
      champ.value = "toto"

      # Get the react props
      props = subject.send(:react_props)

      # Verify the props include specific items, placeholder, name, id, and class
      expect(props[:items]).to include(procedure_separator_option(procedures[0]))
      expect(props[:placeholder]).to eq('Sélectionnez un dossier')
      expect(props[:name]).to eq("dossier[champs_public_attributes][#{champ.public_id}][value]")
      expect(props[:id]).to eq(champ.input_id)
      expect(props[:class]).to eq('small-margin')
    end
  end

  # Context for testing the render_as_radios? method
  context '#render_as_radios?' do
    describe '1 dossier' do
      # Create a dossier in 'en_construction' state for the first procedure
      let(:dossiers_en_construction) { create_dossiers(1, :en_construction, procedures[0]) }
      it {
        procedures[0].dossiers = dossiers_en_construction
        subject.send(:before_render)
        expect(subject.send(:render_as_radios?)).to be_truthy
      }
    end

    describe '5 dossiers' do
      # Create multiple dossiers in different states for the first procedure
      let(:dossiers_en_construction) { create_dossiers(3, :en_construction, procedures[0]) }
      let(:dossiers_accepte) { create_dossiers(1, :accepte, procedures[0]) }
      let(:dossiers_refuse) { create_dossiers(1, :refuse, procedures[0]) }
      it {
        procedures[0].dossiers = dossiers_en_construction + dossiers_accepte + dossiers_refuse
        subject.send(:before_render)
        expect(subject.send(:render_as_radios?)).to be_truthy
      }
    end

    describe '5 dossiers + 2 dossiers in other procedure no limited' do
      # Create multiple dossiers in different states for the first procedure
      let(:dossiers_en_construction) { create_dossiers(3, :en_construction, procedures[0]) }
      let(:dossiers_accepte) { create_dossiers(1, :accepte, procedures[0]) }
      let(:dossiers_refuse) { create_dossiers(1, :refuse, procedures[0]) }

      # Create dossiers not included in the limitation for other procedures
      let(:dossiers_en_construction_no_limited_1) { create_dossiers(1, :en_construction, procedures_no_in_the_limitation[0]) }
      let(:dossiers_en_construction_no_limited_2) { create_dossiers(1, :en_construction, procedures_no_in_the_limitation[1]) }

      it {
        procedures[0].dossiers = dossiers_en_construction + dossiers_accepte + dossiers_refuse
        procedures_no_in_the_limitation[0] = dossiers_en_construction_no_limited_1
        procedures_no_in_the_limitation[1] = dossiers_en_construction_no_limited_2
        subject.send(:before_render)
        expect(subject.send(:render_as_radios?)).to be_truthy
      }
    end

    describe '5 dossiers + 1 dossier brouillon' do
      # Create multiple dossiers in 'en_construction' state and one in 'brouillon' state for the first procedure
      let(:dossiers_en_construction) { create_dossiers(5, :en_construction, procedures[0]) }
      let(:dossiers_brouillon) { create_dossiers(1, :brouillon, procedures[0]) }
      it {
        procedures[0].dossiers = dossiers_en_construction + dossiers_brouillon
        subject.send(:before_render)
        expect(subject.send(:render_as_radios?)).to be_truthy
      }
    end

    describe '5 dossiers + 1 dossier supprime' do
      # Create multiple dossiers in 'en_construction' state and one hidden for the first procedure
      let(:dossiers_en_construction) { create_dossiers(5, :en_construction, procedures[0]) }
      let(:dossiers_supprime) { create_dossiers(1, :en_construction, procedures[0], 1.day.ago) }
      it {
        procedures[0].dossiers = dossiers_en_construction + dossiers_supprime
        subject.send(:before_render)
        expect(subject.send(:render_as_radios?)).to be_truthy
      }
    end

    describe '6 dossiers' do
      # Create 6 dossiers in 'en_construction' state for the first procedure
      let(:dossiers_en_construction) { create_dossiers(6, :en_construction, procedures[0]) }

      it {
        procedures[0].dossiers = dossiers_en_construction
        subject.send(:before_render)
        expect(subject.send(:render_as_radios?)).to be_falsey
      }
    end
  end

  # Context for testing the render_as_combobox? method
  context '#render_as_combobox?' do
    describe 'returns true if there 20 dossiers or more' do
      # Create 20 dossiers in 'en_construction' state for the first procedure
      let(:dossiers_en_construction) { create_dossiers(20, :en_construction, procedures[0]) }

      it {
        procedures[0].dossiers = dossiers_en_construction
        subject.send(:before_render)
        expect(subject.send(:render_as_combobox?)).to be_truthy
      }
    end

    describe 'returns false if there are less than 20 dossiers' do
      # Create 19 dossiers in 'en_construction' state for the first procedure
      let(:dossiers_en_construction) { create_dossiers(19, :en_construction, procedures[0]) }

      it {
        procedures[0].dossiers = dossiers_en_construction
        subject.send(:before_render)
        expect(subject.send(:render_as_combobox?)).to be_falsey
      }
    end
  end

  # Context for testing the dossier_options_for method with dossier states limit
  context 'with dossier states limit' do
    let(:dossier_states_limit) { 1 }
    let(:dossier_states) { [:en_construction, :en_instruction] }

    before do
      allow(champ.type_de_champ).to receive(:options).and_return({ "dossier_states_limit" => dossier_states_limit, "dossier_states" => dossier_states })
    end

    describe 'when dossiers match the limited states' do
      let(:dossiers_brouillon) { create_dossiers(1, :brouillon, procedures[0]) }
      let(:dossiers_en_construction) { create_dossiers(2, :en_construction, procedures[0]) }
      let(:dossiers_accepte) { create_dossiers(1, :accepte, procedures[0]) }

      it 'includes only dossiers with the specified states (except brouillon)' do
        procedures[0].dossiers = dossiers_brouillon + dossiers_en_construction + dossiers_accepte
        subject.send(:before_render)

        options = subject.send(:dossier_options_for, champ)

        expect(options).to include(procedure_separator_option(procedures[0]))
        expect(options).not_to include(dossier_option(dossiers_brouillon[0]))
        expect(options).to include(dossier_option(dossiers_en_construction[0]))
        expect(options).to include(dossier_option(dossiers_en_construction[1]))
        expect(options).not_to include(dossier_option(dossiers_accepte[0]))
      end
    end

    describe 'when no dossiers match the limited states' do
      let(:dossiers_refuse) { create_dossiers(1, :refuse, procedures[0]) }

      it 'returns the correct options indicating no dossiers' do
        procedures[0].dossiers = dossiers_refuse
        subject.send(:before_render)

        options = subject.send(:dossier_options_for, champ)

        expect(options).to include(procedure_separator_option(procedures[0]))
        expect(options).to include(no_dossier_option(1))
        expect(options).to include(procedure_separator_option(procedures[1]))
        expect(options).to include(no_dossier_option(2))
        expect(options).to include(procedure_separator_option(procedures[2]))
        expect(options).to include(no_dossier_option(3))
      end
    end
  end

  # Context for testing the dossier_options_for method when dossier states limit equals 0
  context 'without dossier states limit' do
    let(:dossier_states_limit) { 0 }

    before do
      allow(champ.type_de_champ).to receive(:options).and_return({ "dossier_states_limit" => dossier_states_limit })
    end

    describe 'includes all dossiers regardless of state' do
      let(:dossiers_brouillon) { create_dossiers(1, :brouillon, procedures[0]) }
      let(:dossiers_en_construction) { create_dossiers(2, :en_construction, procedures[0]) }
      let(:dossiers_accepte) { create_dossiers(1, :accepte, procedures[0]) }

      it 'includes all dossiers in the options (except brouillon)' do
        procedures[0].dossiers = dossiers_brouillon + dossiers_en_construction + dossiers_accepte
        subject.send(:before_render)

        options = subject.send(:dossier_options_for, champ)

        expect(options).to include(procedure_separator_option(procedures[0]))
        expect(options).not_to include(dossier_option(dossiers_brouillon[0]))
        expect(options).to include(dossier_option(dossiers_en_construction[0]))
        expect(options).to include(dossier_option(dossiers_en_construction[1]))
        expect(options).to include(dossier_option(dossiers_accepte[0]))
      end
    end
  end
end
