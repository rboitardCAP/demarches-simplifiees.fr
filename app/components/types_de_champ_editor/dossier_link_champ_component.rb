# frozen_string_literal: true

class TypesDeChampEditor::DossierLinkChampComponent < TypesDeChampEditor::BaseChampComponent
  def initialize(procedures:, type_de_champ:, form:, procedure:)
    super(type_de_champ: type_de_champ, form: form, procedure: procedure)
    @procedures = procedures
  end

  def react_props
    {
      id: dom_id(@type_de_champ, :procedures),
      label: "Sélectionnez la ou les démarches concernées",
      items:,
      name: @form.field_name(:procedures, multiple: true),
      selected_keys: @type_de_champ.procedures.map { |procedure| procedure.id.to_s },
      'aria-label': "Liste des démarches",
      secondary_label: "Démarche(s) concernée(s)",
      no_items_label: "Aucune démarche sélectionnée"
    }
  end

  def items
    items = { '--- Démarches publiées ---' => [], '--- Démarches en test ---' => [], '--- Démarches closes ---' => [] }

    @procedures.each do |procedure|
      items["--- Démarches publiées ---"] << { label: "N°#{procedure.id} - #{procedure.libelle}", value: procedure.id.to_s } if procedure.aasm_state == "publiee"
      items["--- Démarches en test ---"] << { label: "N°#{procedure.id} - #{procedure.libelle}", value: procedure.id.to_s } if procedure.aasm_state == "brouillon"
      items["--- Démarches closes ---"] << { label: "N°#{procedure.id} - #{procedure.libelle}", value: procedure.id.to_s } if procedure.aasm_state == "close"
    end

    items
  end

  # Generates properties for the checkbox group
  def checkbox_group_props
    {
      input_name: @form.field_name(:dossier_states, multiple: true),
      item_set: dossier_states_item_set,
      initial_selected_items: form.object.dossier_states,
      group_label: "Sélectionner les états concernés",
      align_horizontally: true
    }
  end

  # Generates item set for dossier states
  #
  # @return [Hash] A hash where keys are dossier states (excluding 'brouillon') and values are their human-readable names
  def dossier_states_item_set
    # Filter out the 'brouillon' state and create a hash with state keys and their human-readable names
    Dossier.states.keys.filter do |state|
      state != Dossier.states[:brouillon]
    end.index_with do |state|
      Dossier.human_attribute_name("state.#{state}")
    end
  end
end
