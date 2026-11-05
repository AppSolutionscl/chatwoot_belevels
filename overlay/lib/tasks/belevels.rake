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
    identifier = ENV.fetch('BELEVELS_INSTALLATION_IDENTIFIER', '').strip.delete('"\'').strip
    if identifier.present?
      if identifier.match?(/\A[0-9A-Za-z]{8}-[0-9A-Za-z]{4}-[0-9A-Za-z]{4}-[0-9A-Za-z]{4}-[0-9A-Za-z]{12}\z/)
        config = InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_IDENTIFIER')
        if config.value != identifier
          config.value = identifier
          config.locked = true
          config.save!
          puts 'be levels: INSTALLATION_IDENTIFIER fijado desde BELEVELS_INSTALLATION_IDENTIFIER'
        else
          puts 'be levels: INSTALLATION_IDENTIFIER ya coincide con BELEVELS_INSTALLATION_IDENTIFIER'
        end
      else
        # No se imprime el valor: solo su forma (9 = dígito, a = letra, ? = otro carácter) para poder diagnosticar.
        forma = identifier.gsub(/[0-9]/, '9').gsub(/[A-Za-z]/, 'a').gsub(/[^9a-]/, '?')
        puts "be levels: BELEVELS_INSTALLATION_IDENTIFIER no tiene formato 8-4-4-4-12 " \
             "(largo #{identifier.length}, forma #{forma}); no se toca INSTALLATION_IDENTIFIER"
      end
    end
  end
end

Rake::Task['db:migrate'].enhance do
  Rake::Task['belevels:marca'].invoke if ActiveRecord::Base.connection.table_exists?('installation_configs')
end
