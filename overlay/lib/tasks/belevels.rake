# be levels · marca de la instalación (nombre, logos). Se aplica sola en cada arranque,
# después de las migraciones (igual que ConfigLoader), así la marca vive en este repositorio
# y no hay que tocar la base ni el panel de Super Admin.
BELEVELS_CONFIG = {
  'INSTALLATION_NAME' => 'CRM be levels Chile',
  'BRAND_NAME' => 'be levels',
  'LOGO' => '/belevels/logo.png',
  'LOGO_DARK' => '/belevels/logo_dark.png',
  'LOGO_THUMBNAIL' => '/belevels/logo_thumbnail.png'
}.freeze

namespace :belevels do
  desc 'Aplica la marca be levels a la configuración de la instalación'
  task marca: :environment do
    BELEVELS_CONFIG.each do |name, value|
      config = InstallationConfig.find_or_initialize_by(name: name)
      next if config.value == value

      config.value = value
      config.save!
      puts "be levels: #{name} = #{value}"
    end
  end
end

Rake::Task['db:migrate'].enhance do
  Rake::Task['belevels:marca'].invoke if ActiveRecord::Base.connection.table_exists?('installation_configs')
end
