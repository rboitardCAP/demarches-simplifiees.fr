class AddDossierStatesToTypeDeChamp < ActiveRecord::Migration[7.1]
  def change
    add_column :types_de_champ, :dossier_states, :string
  end
end
