class AddUiThemeToDistributorsAndWorkers < ActiveRecord::Migration[5.1]
  def change
    add_column :distributors, :ui_theme, :string, default: 'skin-4'
    add_column :site_workers, :ui_theme, :string, default: 'skin-4'
  end
end
