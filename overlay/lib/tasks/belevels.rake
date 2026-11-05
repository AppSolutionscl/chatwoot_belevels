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

    # Identificador de instalación (opcional). Chatwoot lo genera solo la primera vez; si el equipo de Chatwoot
    # asoció la licencia/prueba Enterprise a un identificador concreto, se fija con la variable
    # BELEVELS_INSTALLATION_IDENTIFIER en Dokploy. El plan lo decide siempre el hub de Chatwoot al sincronizar.
    identifier = ENV.fetch('BELEVELS_INSTALLATION_IDENTIFIER', '').strip
    if identifier.present?
      unless identifier.match?(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
        abort "be levels: BELEVELS_INSTALLATION_IDENTIFIER no tiene formato de identificador (8-4-4-4-12, solo 0-9 y a-f)"
      end
      config = InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_IDENTIFIER')
      if config.value != identifier
        config.value = identifier
        config.locked = true
        config.save!
        puts 'be levels: INSTALLATION_IDENTIFIER fijado desde BELEVELS_INSTALLATION_IDENTIFIER'
      end
    end
  end
end

Rake::Task['db:migrate'].enhance do
  Rake::Task['belevels:marca'].invoke if ActiveRecord::Base.connection.table_exists?('installation_configs')
end
