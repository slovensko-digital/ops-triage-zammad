require 'csv'

def load_municipalities
  map = {}
  d = CSV.readlines('db/ops_data/municipality_districts.csv', headers: true)
  d.group_by { |r| r["parent_name"] }.each do |k, v|
    map[k] = {
      name: k,
      value: k,
      children: v.map do |l|
        { name: l["name"], value: "#{k}::#{l["name"]}" }
      end
    }
  end
  d = CSV.readlines('db/ops_data/municipalities.csv', headers: true)
  d.each do |r|
    next if map[r["name"]]
    map[r["name"]] = {
      name: r["name"],
      value: r["name"],
    }
  end
  map.values.sort_by { |v| v[:name] }
end

OPS_OLD_CATEGORIES_MAP = {
  "5" => "Automobily",
  "1" => "Cesty a chodníky",
  "3" => "Dopravné značenie",
  "4" => "Mestský mobiliár",
  "6" => "Verejné služby",
  "7" => "Verejný poriadok",
  "2" => "Zeleň a životné prostredie"
}

OPS_CATEGORIES_MAP = {
  # OLD categories
  [ "5", "Automobily" ] => {
    "dlhodobo odstavené vozidlá" => [ "vozidlo s EČV, s platnou TK a EK", "vozidlo bez EČV, s platnou TK a EK", "vozidlo bez EČV, bez platnej TK a EK", "vozidlo s EČV, bez platnej TK a EK", "nezistené EČV a TK a EK", "zahraničné vozidlo" ],
    "parkovanie" => [ "problémové", "chýbajúce miesta", "nevyznačené miesta" ],
    "iné" => []
  },

  [ "2", "Zeleň a životné prostredie" ] => {
    "neporiadok a odpadky" => [ "neodpratané lístie", "čierne skládky", "neporiadok vo verejnom priestranstve" ],
    "strom" => [ "suchý", "chýbajúci", "neorezaný", "zlomený konár", "napadnutý", "invazívna rastlina", "poškodená podpera" ],
    "trávnatá plocha" => [ "nepokosená", "vyschnutá", "vyjazdené koľaje" ],
    "krík" => [ "suchý", "neostrihaný", "chýbajúci" ],
    "zviera" => [ "túlavé", "uhynuté", "deratizácia" ],
    "znečisťovanie" => [ "ovzdušia", "vody", "pôdy" ],
    "iné" => []
  },

  [ "4", "Mestský mobiliár" ] => {
    "lavička" => [ "chýbajúca", "poškodená", "znečistená" ],
    "socha, pamätník" => [ "znečistená", "poškodená" ],
    "zastávka MHD" => [ "poškodená", "chýbajúca", "znečistená" ],
    "kôš" => [ "poškodený", "preplnený", "chýbajúci", "nevhodne umiestnený", "chýbajúce sáčky" ],
    "detské ihrisko" => [ "poškodené", "chýbajúce", "potrebná údržba" ],
    "cyklostojan" => [ "chýbajúci", "poškodený", "zle umiestnený" ],
    "fontánka" => [ "nefunkčná", "poškodená", "znečistená" ],
    "informačná tabuľa" => [ "poškodená", "zle otočená", "zle umiestnená", "chýbajúca" ],
    "kvetináč" => [ "poškodený", "posunutý", "zanedbaný", "chýbajúci" ],
    "iné" => []
  },

  [ "6", "Verejné služby" ] => {
    "MHD" => [ "technické problémy", "meškanie spojov", "poškodené vozidlo", "zlé nastavenie cestovného poriadku" ],
    "kanalizácia" => [ "upchatá", "chýbajúci kanalizačný poklop", "havária kanalizačného potrubia", "poškodený kanalizačný poklop" ],
    "osvetlenie" => [ "nefunkčné", "poškodené stĺpy", "chýbajúce/nedostatočné", "nevhodné (silné a pod.)" ],
    "webová stránka mesta" => [ "chýbajúce informácie", "neaktuálne informácie", "nesprávne informácie", "nefunkčná stránka" ],
    "rozvodné siete" => [ "poškodená rozvodná skriňa", "nebezpečný kábel" ],
    "zdieľaná mobilita" => [ "nevhodne zaparkovaný dopravný prostriedok", "nevhodne umiestnené parkovisko", "obmedzenie rýchlosti v zóne", "iné" ],
    "iné" => []
  },

  [ "1", "Cesty a chodníky" ] => {
    "schody" => [ "poškodené", "neodhrnuté", "neposypané", "znečistené" ],
    "cesta" => [ "výtlk", "rozbitá (väčší úsek)", "znečistená", "neodhrnutá", "neposypaná", "rozkopaná", "poškodená dlažba" ],
    "chodník" => [ "výtlk", "znečistený", "neodhrnutý", "neposypaný", "bariérový", "rozkopaný", "chýbajúci", "poškodená dlažba", "bariéra na chodníku" ],
    "cyklotrasa" => [ "poškodená", "chýbajúca", "neoznačená", "znečistená", "neodhrnutá", "neposypaná" ],
    "zábradlie" => [ "chýbajúce", "poškodené", "zhrdzavené" ],
    "oplotenie" => [ "chýbajúce", "poškodené", "zhrdzavené" ],
    "iné" => []
  },

  [ "7", "Verejný poriadok" ] => {
    "stavby a budovy" => [ "neohlásené stavebné úpravy", "prekračovanie limitov hluku", "prekračovanie limitov prašnosti", "opustená budova", "zlý stav budovy" ],
    "vandalizmus" => [ "graffiti", "rušenie nočného pokoja", "pitie alkoholu na verejnosti" ],
    "reklama" => [ "vizuálny smog", "nevhodne umiestnená (na chodníku a pod.)", "vylepené plagáty", "nebezpečná (na spadnutie a pod.)" ],
    "iné" => []
  },

  [ "3", "Dopravné značenie" ] => {
    "priechod pre chodcov" => [ "chýbajúci", "zle viditeľný" ],
    "semafor" => [ "nefunkčný", "zle nastavený", "chýbajúci" ],
    "dopravné zrkadlo" => [ "chýbajúce", "zle natočené", "poškodené" ],
    "vodorovná značka" => [ "chýbajúca", "neaktuálna", "zle viditeľná" ],
    "riešenie dopravnej situácie" => [ "nebezpečné", "dopravu spomaľujúce", "nedodržiavanie dopravných predpisov" ],
    "zvislá značka" => [ "poškodená", "neaktuálna", "chýbajúca", "vyblednutá", "zle otočená" ],
    "spomaľovač" => [ "chýbajúci", "poškodený" ],
    "betónová zábrana (biskupský klobúk)" => [ "chýbajúca", "posunutá", "poškodená" ],
    "stĺpik" => [ "chýbajúci", "poškodený", "nadbytočný" ],
    "iné" => []
  },

  # NEW categories
  "Komunikácie": {
    "cesta": [ "výtlk", "rozbitá cesta (väčší úsek)", "znečistená", "neodhrnutá", "neposypaná", "rozkopaná", "poškodená dlažba" ],
    "chodník": [ "výtlk", "znečistený", "neodhrnutý", "neposypaný", "rozkopaný", "chýbajúci", "poškodená dlažba", "bariéra na chodníku" ],
    "cyklotrasa": [ "poškodená", "chýbajúca", "neoznačená", "znečistená", "neodhrnutá", "neposypaná", "výtlk" ],
    "schody": [ "poškodená", "znečistená", "neodhrnutá", "neposypaná", "bariérové" ],
    "podjazd/podchod": [ "potrebná údržba" ],
    "most/lávka": [ "poškodená", "", "chýbajúca", "nevhodne umiestnená" ],
  },
  "Mobiliár": {
    "kôš": [ "poškodený", "preplnený", "chýbajúci", "nevhodne umiestnený", "chýbajúce sáčky" ],
    "kvetináč": [ "poškodený", "posunutý", "zanedbaný", "chýbajúci" ],
    "cyklostojan": [ "chýbajúci", "poškodený", "zle umiestnený" ],
    "rozvodná skriňa": [ "poškodená rozvodná skriňa", "nebezpečný kábel" ],
    "zábradlie/oplotenie": [ "chýbajúce", "poškodené", "zhrdzavené" ],
    "socha/pamätník/pietne miesto": [ "znečistené", "poškodené" ],
    "pitná fontána": [ "nefunkčná", "poškodená", "znečistená" ],
    "fontána": [ "nefunkčná", "poškodená", "znečistená" ],
    "informačná/smerová tabuľa": [ "chýbajúca", "poškodená", "zle otočená", "zle umiestnená" ],
    "výťah": [ "chýbajúci", "poškodený", "znečistený" ],
    "lavička": [ "chýbajúca", "poškodená", "znečistená" ],
    "verejná toaleta": [ "znečistená", "nefunkčná", "uzavretá" ]
  },
  "Značenie": {
    "vodorovné dopravné značenie": [ "chýbajúce", "neaktuálne", "zle viditeľné" ],
    "zvislé dopravné značenie": [ "poškodené", "neaktuálne", "chýbajúce", "vyblednuté", "zle otočené" ],
    "semafor": [ "nefunkčný", "zle nastavený", "chýbajúci" ],
    "spomaľovač": [ "chýbajúci", "poškodený" ],
    "dopravné zrkadlo": [ "chýbajúce", "poškodené", "zle natočené" ],
    "priechod pre chodcov": [ "chýbajúci", "zle viditeľný", "bariérový" ],
    "protiparkovacia zábrana/stĺpik/biskupský klobúk": [ "chýbajúca", "poškodená", "posunutá" ],
  },
  "Osvetlenie": {
    "osvetlenie": [ "nefunknčné", "poškodený stĺp", "chýbajúce", "nedostatočné", "nevhodné (silné a pod.)" ],
  },
  "Kanalizácia": {
    "kanalizáčná vpusť": [ "upchatá", "chýbajúci kanalizačný poklop", "poškodený kanalizačný poklop", "havária kanalizačného potrubia" ],
    "kanalizáčná mriežka": [ "upchatá", "poškodená", "chýbajúca" ],
  },
  "Mestská hromadná doprava": {
    "služby hromadnej dopravy": [ "meškanie spojov" ],
    "grafikon / zlé nastavenie cestovného poriadku": [ "poškodenie vozidla" ],
    "MHD zastávka": [ "poškodená", "chýbajúca", "znečistená" ],
  },
  "Ihrisko": {
    "športové ihrisko": [ "poškodené", "chýbajúce", "potrebná údržba" ],
    "detské ihrisko": [ "poškodené", "chýbajúce", "potrebná údržba" ]
  },
  "Verejný poriadok": {
    "reklama": [ "nelegálna reklama", "nevhodne umiestnená", "nebezpečná (na spadnutie a pod)" ],
    "neporiadok vo verejnom priestranstve": [ "neodpratané lístie", "neporiadok vo verejnom priestore" ],
    "vandalizmus": [ "rušenie nočného pokoja", "pitie alkoholu na verejnom priestore" ],
    "iné": []
  },
  "Dopravné riešenie": {
    "nebezpečné": [ "návrh na riešenie" ],
    "dopravu spomaľujúce": [ "návrh na riešenie" ],
    "obchádzková trasa": [ "bariérová", "zle vyznačená", "nebezpečná" ]
  },
  "Zdieľaná mikromobilita": {
    "bicykle": [ "nevhodne zaparkovaný dopravný prostriedok", "nevhodne umiestnené parkovisko" ],
    "kolobežky": [ "nevhodne zaparkovaný dopravný prostriedok", "nevhodne umiestnené parkovisko" ]
  },
  "Zeleň a znečisťovanie": {
    "kosenie": [ "nepravidelne" ],
    "strom": [ "suchý", "chýbajúci", "neorezaný", "zlomený konár", "napadnutý", "invazívna rastlina", "poškodená podpera" ],
    "krík": [ "suchý", "chýbajúci", "neorezaný" ],
    "výsadba": [ "chýbajúca", "neudržiavaná" ],
    "ostatná starostlivosť": [ "iné" ],
    "znečisťovanie": [ "voda, pôda, ovzdušie" ]
  },
  "Stavby": {
    "budova": [ "poškodená", "grafiti", "nevyužívaná" ],
    "most": [ "poškodený", "grafiti" ],
    "stánok": [ "poškodený", "grafiti", "nevyužívaný" ],
    "letná terasa": [ "preverenie povolenia" ]
  },
  "Zvieratá": {
    "zver v meste": [ "premnožené hlodavce" ],
    "výbehy pre zvieratá": [ "lesná zver", "túlavé mačky/psy", "hmyz" ],
    "domáce zvieratá": [ "výbehy pre zvieratá", "majitelia - neplnenie povinností" ],
    "mŕtvy živočích": [],
    "iné": []
  },
  "Skládky a vraky": {
    "nelegálne skládky": [],
    "vraky motorových vozidiel": [],
    "kontajnerové stanovištia": [ "chýbajúce" ],
    "kompostovanie": [ "chýbajúce komunitné kompostovisko", "domácnosti" ]
  },
  "Kontakt so samosprávou": {
    "webová stránka mesta": [ "chýbajúca informácia", "neaktuálne informácie", "nefunkčná stránka" ],
    "mobilná aplikácia mesta": [ "chýbajúca informácia", "neaktuálne informácie", "nefunkčná aplikácia" ],
    "verejný rozhlas": [ "chýbajúci", "pokazený" ]
  },
  "Verejné služby": {
    "iné": []
  },
  "Iné": {
    "iné": []
  },
  "Ostatné": {
    "iné": []
  }
}

def setup_elastic
  puts "Setting up Elasticsearch..."
  Setting.set('es_url', "#{ENV.fetch('ELASTICSEARCH_SCHEMA')}://#{ENV.fetch('ELASTICSEARCH_HOST')}:#{ENV.fetch('ELASTICSEARCH_PORT')}")
  Setting.set('es_user', ENV.fetch('ELASTICSEARCH_USER'))
  Setting.set('es_password', ENV.fetch('ELASTICSEARCH_PASS'))
  Setting.set('es_index', ENV.fetch('ELASTICSEARCH_NAMESPACE'))
end

class RequestMock
  attr_accessor :remote_ip, :env
  def initialize(remote_ip, env)
    @remote_ip = remote_ip
    @env = env
  end
end

def setup_admin_user
  admin_user_data = {
    email: ENV.fetch('ADMIN_EMAIL'),
    password: ENV.fetch('ADMIN_PASSWORD'),
    firstname: ENV.fetch('ADMIN_FIRSTNAME'),
    lastname: ENV.fetch('ADMIN_LASTNAME')
  }

  request = RequestMock.new('127.0.0.1', { 'HTTP_ACCEPT_LANGUAGE' => ENV.fetch('DEFAULT_LOCALE', 'sk') })
  Service::User::AddFirstAdmin.new.execute(user_data: admin_user_data, request: request)
end

def setup_google_oauth
  return unless ENV['GOOGLE_OAUTH2_CLIENT_ID'].present? && ENV['GOOGLE_OAUTH2_CLIENT_SECRET'].present?

  Rails.logger.info "Setting up Google OAuth2..."
  Setting.set("auth_google_oauth2", true)
  Setting.set("auth_google_oauth2_credentials", {
    "client_id"=>ENV.fetch('GOOGLE_OAUTH2_CLIENT_ID'),
    "client_secret"=>ENV.fetch('GOOGLE_OAUTH2_CLIENT_SECRET')
  })
end

namespace :ops do
  namespace :triage do
    desc "Migrates triage environment"
    task migrate: :environment do
      next unless User.any?

      puts "Migrating triage environment..."
      if User.count <= 2
        setup_admin_user

        Rails.logger.info "Setting branding..."
        Setting.set('fqdn', ENV.fetch('FQDN'))
        Setting.set('product_name', ENV.fetch('PRODUCT_NAME'))
        Setting.set('organization', ENV.fetch('ORGANIZATION'))
        Setting.set('http_type', ENV.fetch('HTTP_TYPE', 'http'))
        Setting.set('ticket_hook', "Tiket#")
      end

      Ticket::Article::Type.find_by_name(:note).update!(communication: true)

      Setting.set('user_create_account', false) # Disable user creation via web interface
      Setting.set('api_password_access', false) # Disable password access to REST API

      Setting.set('auth_third_party_auto_link_at_inital_login', true)
      Setting.set('auth_third_party_no_create_user', true)

      Setting.set('customer_ticket_create', false) # disable WEB interface ticket creation

      Setting.set('ui_ticket_zoom_sidebar_article_attachments', 'true')

      setup_elastic if ENV['ELASTICSEARCH_ENABLED'] == 'true'

      setup_google_oauth

      # create role for Portal users
      Role.find_or_initialize_by(name: 'Portal User').tap do |role|
        role.note = __('OPS Portal users.')
        role.default_at_signup = false
        role.preferences = {}
        role.updated_by_id = 1
        role.created_by_id = 1
      end.save!

      # create role for External Responsible Subjects
      external_role = Role.find_or_initialize_by(name: 'Externý zodpovedný subjekt').tap do |role|
        role.default_at_signup = false
        role.preferences = {}
        role.updated_by_id = 1
        role.created_by_id = 1
      end
      external_role.save!

      # create user used for templates
      template_external_responsible_subject_user = User.create_if_not_exists(
        login: 'template-ext',
        firstname: 'Vzor',
        lastname: 'Externý zodpovedný subjekt',
        email: '',
        active: false,
        role_ids: [external_role.id],
        updated_by_id: 1,
        created_by_id: 1,
      )

      # create Incoming group
      incoming_group = Group.find_or_initialize_by(name: 'Incoming').tap do |group|
        group.note = __('OPS Incoming tickets group.')
        group.active = true
        group.updated_by_id = 1
        group.created_by_id = 1
      end
      incoming_group.save!

      # create role for Portal Tech Account
      portal_tech_account = Role.find_or_initialize_by(name: 'Portal Tech Account').tap do |role|
        role.note = __('OPS Portal tech account.')
        role.active = true
        role.updated_by_id = 1
        role.created_by_id = 1
      end
      portal_tech_account.permission_grant('admin.user')
      portal_tech_account.permission_grant('admin.group')
      portal_tech_account.permission_grant('admin.ticket')
      portal_tech_account.permission_grant('ticket.agent')
      portal_tech_account.permission_grant('user_preferences.access_token')
      portal_tech_account.groups << incoming_group
      portal_tech_account.save!

      params = {
        "firstname":"Aplikácia",
        "lastname":"Odkaz pre starostu",
        "note":"",
        "role_ids": [ portal_tech_account.id, Role.find_by(name: "Admin").id ],
        "active":true,
        "vip":false,
        "updated_by_id": "1",
        "created_by_id": "1",
      }
      tech_user = User.find_or_initialize_by(firstname: 'Aplikácia', lastname: 'Odkaz pre starostu').tap do |tech_user|
        tech_user.assign_attributes(params)
      end
      tech_user.save!

      token = Token.find_or_initialize_by(name: "Token for OPS Portal and API")
      token.action = 'api'
      token.persistent = true
      token.user_id = tech_user.id
      token.preferences = {"permission"=>["admin.user", "admin.group", "report", "ticket.agent", "admin.ticket"]}
      token.token = ENV.fetch('API_TOKEN', SecureRandom.urlsafe_base64(48))
      token.save!

      ObjectManager::Attribute.add(
        object: 'Ticket',
        name: 'process_type',
        display: __('Proces'),
        data_type: 'select',
        data_option: {
          options: {
            "portal_issue_triage" => "Triáž podnetu",
            "portal_issue_resolution" => "Riešenie podnetu",
            "portal_issue_verification" => "Aktualizácia podnetu",
            "portal_comment_report" => "Nahlásený komentár"
          },
          default: '',
          maxlength: 255,
          nulloption: true,
          null: true,
        },
        active: true,
        screens: {
          edit: {
            'ticket.agent' => { shown: false },
          },
        },
        position: 2,
        created_by_id: 1,
        updated_by_id: 1,
      )

      ObjectManager::Attribute.add(
        object: 'Ticket',
        name: 'issue_type',
        display: __('Typ dopytu'),
        data_type: 'select',
        data_option: {
          options: [
            { name: 'Podnet', value: 'issue' },
            { name: 'Otázka', value: 'question' },
            { name: 'Pochvala', value: 'praise' }
          ],
          customsort: 'on',
          default: '',
          null: true,
          nulloption: true,
          maxlength: 255,
        },
        active: true,
        screens: {
          create_middle: {
            'ticket.customer' => { shown: false },
            'ticket.agent' => { shown: false }
          },
          edit: {
            'ticket.customer' => { shown: false },
            'ticket.agent' => { shown: false }
          }
        },
        position: 15,
        created_by_id: 1,
        updated_by_id: 1
      )

      ObjectManager::Attribute.add(
        object: 'Ticket',
        name: 'category',
        display: __('Kategória'),
        data_type: 'select',
        data_option: {
          options: OPS_CATEGORIES_MAP.keys.map do |k|
            if k.is_a?(Array)
              { "name" => k.last, "value" => k.first }
            else
              { "name" => k.to_s, "value" => k.to_s }
            end
          end,
          customsort: 'on',
          default: '',
          null: true,
          nulloption: true,
          maxlength: 255,
        },
        active: true,
        screens: {
          create_middle: {
            'ticket.customer' => { shown: false },
            'ticket.agent' => { shown: false }
          },
          edit: {
            'ticket.customer' => { shown: false },
            'ticket.agent' => { shown: false }
          }
        },
        position: 17,
        created_by_id: 1,
        updated_by_id: 1
      )

      ObjectManager::Attribute.add(
        object: 'Ticket',
        name: 'origin',
        display: __('Zdroj tiketu'),
        data_type: 'select',
        data_option: {
          options: [
            { name: 'Portál', value: 'portal' },
          ],
          customsort: 'off',
          default: '',
          null: true,
          nulloption: true,
          maxlength: 255,
        },
        active: true,
        screens: {
          create_middle: {
            'ticket.customer' => { shown: false },
            'ticket.agent' => { shown: false }
          },
          edit: {
            'ticket.customer' => { shown: false },
            'ticket.agent' => { shown: false }
          }
        },
        position: 2000,
        created_by_id: 1,
        updated_by_id: 1
      )

      {
        'address_state' => 'Adresa (Kraj)',
        'address_county' => 'Adresa (Okres)',
        'address_street' => 'Adresa (Ulica)',
        'address_house_number' => 'Adresa (Číslo domu)',
      }.each.with_index(51) do |(name, title), position|
        ObjectManager::Attribute.find_by_name(name)&.update(editable: true) # allow editing in migration
        ObjectManager::Attribute.add(
          object: 'Ticket',
          name: name.dup,
          display: __(title),
          data_type: 'input',
          data_option: {
            type: 'text',
            default: '',
            null: true,
            maxlength: 255,
          },
          active: true,
          screens: {
            create_middle: {
              'ticket.customer' => { shown: false },
              'ticket.agent' => { shown: false }
            },
            edit: {
              'ticket.customer' => { shown: false },
              'ticket.agent' => { shown: false }
            }
          },
          position: position,
          created_by_id: 1,
          updated_by_id: 1
        )
      end

      ObjectManager::Attribute.add(
        object: 'Ticket',
        name: 'ops_state',
        display: __('Stav v Odkaze pre starostu'),
        data_type: 'select',
        data_option: {
          options: {
            "waiting" => "Čakajúci",
            "rejected" => "Zamietnutý",
            "sent_to_responsible" => "Zaslaný zodpovednému",
            "in_progress" => "V riešení",
            "marked_as_resolved" => "Označený za vyriešený",
            "resolved" => "Vyriešený",
            "unresolved" => "Neriešený",
            "closed" => "Uzavretý",
            "referred" => "Odstúpený",
            "accepted" => "Prijatý",
            "duplicate" => "Duplicitný",
            "archived" => "Archivovaný"
          },
          default: 'waiting',
          nulloption: true,
          null: true,
        },
        active: true,
        screens: {
          create_middle: {
            'ticket.agent' => { shown: false },
            'ticket.customer' => { shown: false },
          },
          edit: {
            'ticket.agent' => { shown: false },
            'ticket.customer' => { shown: false },
          }
        },
        position: 38,
        created_by_id: 1,
        updated_by_id: 1
      )

      subcategory_names = OPS_CATEGORIES_MAP.values.flat_map { |v| v.keys.map(&:to_s) }.uniq - [ "" ]
      ObjectManager::Attribute.add(
        object: 'Ticket',
        name: 'subcategory',
        display: __('Podkategória'),
        data_type: 'select',
        data_option: {
          options: subcategory_names.map { |v| { name: v, value: v } },
          customsort: 'on',
          default: '',
          null: true,
          nulloption: true,
          maxlength: 255,
        },
        active: true,
        screens: {
          create_middle: {
            'ticket.customer' => { shown: false },
            'ticket.agent' => { shown: false }
          },
          edit: {
            'ticket.customer' => { shown: false },
            'ticket.agent' => { shown: false }
          }
        },
        position: 19,
        created_by_id: 1,
        updated_by_id: 1
      )

      subtype_names = OPS_CATEGORIES_MAP.values.flat_map { |v| v.values }.flatten.uniq - [ "" ]
      ObjectManager::Attribute.add(
        object: 'Ticket',
        name: 'subtype',
        display: __('Typ Problému'),
        data_type: 'select',
        data_option: {
          options: subtype_names.map { |v| { name: v, value: v } },
          customsort: 'on',
          default: '',
          null: true,
          nulloption: true,
          maxlength: 255,
        },
        active: true,
        screens: {
          create_middle: {
            'ticket.customer' => { shown: false },
            'ticket.agent' => { shown: false }
          },
          edit: {
            'ticket.customer' => { shown: false },
            'ticket.agent' => { shown: false }
          }
        },
        position: 20,
        created_by_id: 1,
        updated_by_id: 1
      )

      ObjectManager::Attribute.find_by_name('likes_count')&.update(editable: true)
      ObjectManager::Attribute.add(
        object: 'Ticket',
        name: 'likes_count',
        display: __('Počet hlasov'),
        data_type: 'integer',
        data_option: {
          "default" => nil, "min" => 0, "max" => 999999999, "null" => true, "options" => {}, "relation" => ""
        },
        active: true,
        screens: {
          edit: {
            'ticket.agent' => { shown: false },
            'ticket.customer' => { shown: false },
          },
          create_middle: {
            'ticket.agent' => { shown: false },
            'ticket.customer' => { shown: false },
          }
        },
        position: 100,
        created_by_id: 1,
        updated_by_id: 1,
      )

      # load municipalities
      a = ObjectManager::Attribute.find_by(name: 'address_municipality', object_lookup_id: ObjectLookup.by_name('Ticket'))

      a.data_option['options'] = load_municipalities
      a.save!

      ObjectManager::Attribute.add(
        object: 'Ticket',
        name: 'portal_duplicates_url',
        display: 'Podobné podnety v okolí',
        data_type: 'input',
        data_option: {
          default: 'Odkaz na podobné podnety',
          type: 'text',
          maxlength: 120,
          linktemplate: File.join(
            ENV.fetch('OPS_PORTAL_PUBLIC_URL', ENV.fetch('OPS_PORTAL_URL', 'http://host.docker.internal:3000')),
            'dopyty?dopyt[]=Podnet&kategoria[]=#{ticket.category.value}&pin=#{ticket.address_lat},#{ticket.address_lon}'
          ),
          null: true,
          options: {},
          relation: ''
        },
        active: true,
        screens: {
          create_middle: {
            'ticket.customer' => { shown: false },
            'ticket.agent' => { shown: false }
          },
          edit: {
            'ticket.customer' => { shown: false },
            'ticket.agent' => { shown: false }
          }
        },
        position: 102,
        created_by_id: 1,
        updated_by_id: 1
      )

      ObjectManager::Attribute.migration_execute

      # add ops flows
      CoreWorkflow.find_or_initialize_by(name: 'ops - ticket - triage process - setup attributes').tap do |flow|
        flow.object = "Ticket"
        flow.preferences = { "screen" => [ "edit" ] }
        flow.condition_saved = {
          "ticket.origin" => { "operator" => "is", "value" => [ "portal" ] },
          "ticket.process_type" => { "operator" => "is", "value" => [ "portal_issue_triage" ] },
          "ticket.issue_type" => { "operator" => "is", "value" => [ "issue", "question" ] }
        }
        flow.condition_selected = {}
        flow.perform = {
          "ticket.process_type" => { "operator" => "show", "show" => "true" },
          "ticket.issue_type" => {
            "operator" => [ "show", "set_fixed_to" ],
            "show" => "true",
            "set_fixed_to" => [ "issue", "question" ]
          },
          "ticket.origin" => { "operator" => "show", "show" => "true" },
          "ticket.body" => { "operator" => "show", "show" => "true" },
          "ticket.category" => { "operator" => "show", "show" => "true" },
          "ticket.subcategory" => { "operator" => "show", "show" => "true" },
          "ticket.subtype" => { "operator" => "show", "show" => "true" },
          "ticket.responsible_subject" => { "operator" => "show", "show" => "true" },
          "ticket.ops_state" => {
            "operator" => [ "show", "set_fixed_to"],
            "show" => "true",
            "set_fixed_to" => [ "waiting", "sent_to_responsible" , "rejected", "duplicate" ]
          },
          "ticket.address_municipality" => { "operator" => "show", "show" => "true" },
          "ticket.address_state" => { "operator" => "show", "show" => "true" },
          "ticket.address_county" => { "operator" => "show", "show" => "true" },
          "ticket.address_street" => { "operator" => "show", "show" => "true" },
          "ticket.address_house_number" => { "operator" => "show", "show" => "true" },
          "ticket.address_postcode" => { "operator" => "show", "show" => "true" },
          "ticket.address_lat" => { "operator" => "show", "show" => "true" },
          "ticket.address_lon" => { "operator" => "show", "show" => "true" },
          "ticket.portal_url" => { "operator" => "show", "show" => "true" },
        }
        flow.active = true
        flow.stop_after_match = false
        flow.changeable = true # TODO consider hiding from end users
        flow.priority = 150
        flow.updated_by_id = 1
        flow.created_by_id = 1
      end.save!

      CoreWorkflow.find_or_initialize_by(name: 'ops - ticket - triage process - praise - setup attributes').tap do |flow|
        flow.object = "Ticket"
        flow.preferences = { "screen" => [ "edit" ] }
        flow.condition_saved = {
          "ticket.origin" => { "operator" => "is", "value" => [ "portal" ] },
          "ticket.process_type" => { "operator" => "is", "value" => [ "portal_issue_triage" ] },
          "ticket.issue_type" => { "operator" => "is", "value" => [ "praise" ] }
        }
        flow.condition_selected = {}
        flow.perform = {
          "ticket.process_type" => { "operator" => "show", "show" => "true" },
          "ticket.issue_type" => { "operator" => [ "show", "set_readonly"],  "show" => "true", "set_readonly" => "true" },
          "ticket.portal_public" => { "operator" => [ "show", "set_readonly"], "show" => "true", "set_readonly" => "true" },
          "ticket.origin" => { "operator" => "show", "show" => "true" },
          "ticket.body" => { "operator" => "show", "show" => "true" },
          "ticket.responsible_subject" => { "operator" => "show", "show" => "true" },
          "ticket.ops_state" => {
            "operator" => [ "show", "set_fixed_to"],
            "show" => "true",
            "set_fixed_to" => [ "waiting", "rejected", "resolved", "unresolved" ]
          },
          "ticket.address_municipality" => { "operator" => "show", "show" => "true" },
        }
        flow.active = true
        flow.stop_after_match = false
        flow.changeable = true # TODO consider hiding from end users
        flow.priority = 150
        flow.updated_by_id = 1
        flow.created_by_id = 1
      end.save!

      CoreWorkflow.find_or_initialize_by(name: 'ops - ticket - triage process - praise - setup ops_states if not public').tap do |flow|
        flow.object = "Ticket"
        flow.preferences = { "screen" => [ "edit" ] }
        flow.condition_saved = {
          "ticket.origin" => { "operator" => "is", "value" => [ "portal" ] },
          "ticket.process_type" => { "operator" => "is", "value" => [ "portal_issue_triage" ] },
          "ticket.issue_type" => { "operator" => "is", "value" => [ "praise" ] },
          "ticket.portal_public" => { "operator" => "is", "value" => [ "false" ] }
        }
        flow.condition_selected = {}
        flow.perform = {
          "ticket.ops_state" => {
            "operator" => [ "show", "set_fixed_to"],
            "show" => "true",
            "set_fixed_to" => [ "waiting", "rejected", "unresolved" ]
          },
        }
        flow.active = true
        flow.stop_after_match = false
        flow.changeable = true # TODO consider hiding from end users
        flow.priority = 149
        flow.updated_by_id = 1
        flow.created_by_id = 1
      end.save!

      CoreWorkflow.find_or_initialize_by(name: 'ops - ticket - resolution process - setup attributes').tap do |flow|
        flow.object = "Ticket"
        flow.preferences = { "screen" => [ "edit" ] }
        flow.condition_saved = {
          "ticket.origin" => { "operator" => "is", "value" => [ "portal" ] },
          "ticket.process_type" => { "operator" => "is", "value" => [ "portal_issue_resolution" ] }
        }
        flow.condition_selected = {}
        flow.perform = {
          "ticket.process_type" => { "operator" => "show", "show" => "true" },
          "ticket.issue_type" => {
            "operator" => [ "show", "set_fixed_to" ],
            "show" => "true",
            "set_fixed_to" => [ "issue", "question" ]
          },
          "ticket.likes_count" => { "operator" => "show", "show" => "true" },
          "ticket.origin" => { "operator" => "show", "show" => "true" },
          "ticket.responsible_subject_changed_at" => { "operator" => "show", "show" => "true" },
          "ticket.category" => { "operator" => "show", "show" => "true" },
          "ticket.subcategory" => { "operator" => "show", "show" => "true" },
          "ticket.subtype" => { "operator" => "show", "show" => "true" },
          "ticket.responsible_subject" => { "operator" => "show", "show" => "true" },
          "ticket.ops_state" => {
            "operator" => [ "show", "set_fixed_to"],
            "show" => "true",
            "set_fixed_to" => [ "rejected", "sent_to_responsible", "in_progress", "marked_as_resolved", "resolved", "unresolved", "closed", "referred", "duplicate" ]
          },
          "ticket.address_municipality" => { "operator" => "show", "show" => "true" },
          "ticket.address_state" => { "operator" => "show", "show" => "true" },
          "ticket.address_county" => { "operator" => "show", "show" => "true" },
          "ticket.address_street" => { "operator" => "show", "show" => "true" },
          "ticket.address_house_number" => { "operator" => "show", "show" => "true" },
          "ticket.address_postcode" => { "operator" => "show", "show" => "true" },
          "ticket.address_lat" => { "operator" => "show", "show" => "true" },
          "ticket.address_lon" => { "operator" => "show", "show" => "true" },
          "ticket.portal_url" => { "operator" => "show", "show" => "true" },
          "ticket.investment" => { "operator" => "show", "show" => "true" },
        }
        flow.active = true
        flow.stop_after_match = false
        flow.changeable = true # TODO consider hiding from end users
        flow.priority = 150
        flow.updated_by_id = 1
        flow.created_by_id = 1
      end.save!

      CoreWorkflow.find_or_initialize_by(name: 'ops - ticket - portal issue verification process - setup attributes').tap do |flow|
        flow.object = "Ticket"
        flow.preferences = { "screen" => [ "edit" ] }
        flow.condition_saved = {
          "ticket.origin" => { "operator" => "is", "value" => [ "portal" ] },
          "ticket.process_type" => { "operator" => "is", "value" => [ "portal_issue_verification" ] }
        }
        flow.condition_selected = {}
        flow.perform = {
          "ticket.process_type" => { "operator" => "show", "show" => "true" },
          "ticket.issue_resolved" => { "operator" => "show", "show" => "true" },
          "ticket.ops_state" => {
            "operator" => [ "show", "set_fixed_to"],
            "show" => "true",
            "set_fixed_to" => [ "waiting", "rejected", "accepted" ]
          },
          "ticket.portal_url" => { "operator" => "show", "show" => "true" },
        }
        flow.active = true
        flow.stop_after_match = false
        flow.changeable = true # TODO consider hiding from end users
        flow.priority = 150
        flow.updated_by_id = 1
        flow.created_by_id = 1
      end.save!

      CoreWorkflow.find_or_initialize_by(name: 'ops - ticket - portal issue verification process - setup issue_resolved').tap do |flow|
        flow.object = "Ticket"
        flow.preferences = { "screen" => [ "edit" ] }
        flow.condition_saved = {
          "ticket.origin" => { "operator" => "is", "value" => [ "portal" ] },
          "ticket.process_type" => { "operator" => "is", "value" => [ "portal_issue_resolved_verification" ] },
          "ticket.issue_resolved" => { "operator" => "is", "value" => [ "true", "false" ] }
        }
        flow.condition_selected = {}
        flow.perform = {
          "ticket.issue_resolved" => { "operator" => [ "show"], "show" => "true" },
        }
        flow.active = true
        flow.stop_after_match = false
        flow.changeable = false
        flow.priority = 150
        flow.updated_by_id = 1
        flow.created_by_id = 1
      end.save!

      CoreWorkflow.find_or_initialize_by(name: 'ops - ticket - show portal duplicates url if issue_type issue').tap do |flow|
        flow.object = "Ticket"
        flow.preferences = { "screen" => [ "edit" ] }
        flow.condition_saved = {
          "ticket.origin" => { "operator" => "is", "value" => [ "portal" ] },
          "ticket.issue_type" => { "operator" => "is", "value" => [ "issue" ] }
        }
        flow.condition_selected = {}
        flow.perform = {
          "ticket.portal_duplicates_url" => { "operator" => "show", "show" => "true" }
        }
        flow.active = true
        flow.stop_after_match = false
        flow.changeable = true # TODO consider hiding from end users
        flow.priority = 150
        flow.updated_by_id = 1
        flow.created_by_id = 1
      end.save!

      CoreWorkflow.find_or_initialize_by(name: 'ops - read-only ticket attributes').tap do |flow|
        flow.object = "Ticket"
        flow.preferences = { "screen" => [ "edit" ] }
        flow.condition_saved = {}
        flow.condition_selected = {}
        flow.perform = {
          "ticket.process_type" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.likes_count" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.origin" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.responsible_subject_changed_at" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.portal_url" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.portal_duplicates_url" => { "operator" => "set_readonly", "set_readonly" => "true" },
        }
        flow.active = true
        flow.stop_after_match = false
        flow.changeable = true # TODO consider hiding from end users
        flow.priority = 100
        flow.updated_by_id = 1
        flow.created_by_id = 1
      end.save!

      CoreWorkflow.find_or_initialize_by(name: 'ops - show read-only user origin if set').tap do |flow|
        flow.object = "User"
        flow.preferences = { "screen" => [ "edit" ] }
        flow.condition_saved = { "user.origin" => { "operator" => "is set", "value" => [] }}
        flow.condition_selected = {}
        flow.perform = { "customer.origin" => { "operator" => [ "set_readonly", "show" ], "set_readonly" => "true", "show" => "true" } }
        flow.active = true
        flow.stop_after_match = false
        flow.changeable = true # TODO consider hiding from end users
        flow.priority = 100
        flow.updated_by_id = 1
        flow.created_by_id = 1
      end.save!

      CoreWorkflow.find_or_initialize_by(name: 'ops - reset subcategory when category not set').tap do |flow|
        flow.object = "Ticket"
        flow.preferences = { "screen" => [ "create_middle", "edit" ] }
        flow.condition_saved = {}
        flow.condition_selected = { "ticket.category" => { "operator" => "not set", "value" => [] } }
        flow.perform = { "ticket.subcategory" => { "operator" => [ "set_fixed_to", "select" ], "set_fixed_to" => [ "" ], "select" => "" } }
        flow.active = true
        flow.stop_after_match = false
        flow.changeable = true
        flow.priority = 500
        flow.updated_by_id = 1
        flow.created_by_id = 1
      end.save!

      CoreWorkflow.find_or_initialize_by(name: 'ops - reset type when subcategory not set').tap do |flow|
        flow.object = "Ticket"
        flow.preferences = { "screen" => [ "create_middle", "edit" ] }
        flow.condition_saved = {}
        flow.condition_selected = { "ticket.subcategory" => { "operator" => "not set", "value" => [] } }
        flow.perform = { "ticket.subtype" => { "operator" => [ "set_fixed_to", "select" ], "set_fixed_to" => [ "" ], "select" => "" } }
        flow.active = true
        flow.stop_after_match = false
        flow.changeable = true
        flow.priority = 550
        flow.updated_by_id = 1
        flow.created_by_id = 1
      end.save!

      CoreWorkflow.find_or_initialize_by(name: 'ops - show only new categories').tap do |flow|
        flow.object = "Ticket"
        flow.preferences = { "screen" => [ "edit" ] }
        flow.condition_saved = {}
        flow.condition_selected = { "ticket.category" => { "operator" => "is not", "value" => OPS_OLD_CATEGORIES_MAP.keys } }
        flow.perform = { "ticket.category" => { "operator" => "remove_option", "remove_option" => OPS_OLD_CATEGORIES_MAP.keys } }
        flow.active = true
        flow.stop_after_match = false
        flow.changeable = true
        flow.priority = 450
        flow.updated_by_id = 1
        flow.created_by_id = 1
      end.save!

      OPS_CATEGORIES_MAP.each do |cat, subcats|
        cat_name = cat.is_a?(Array) ? cat.last : cat
        cat_value = cat.is_a?(Array) ? cat.first : cat
        cwf = CoreWorkflow.find_or_initialize_by(name: "ops - category - #{cat_name} - #{cat_value} - visible options").tap do |flow|
          flow.object = "Ticket"
          flow.preferences = { "screen" => [ "create_middle", "edit" ] }
          flow.condition_saved = {}
          flow.condition_selected = { "ticket.category" => { "operator" => "is", "value" => [ cat_value.to_s ] } }
          flow.perform = { "ticket.subcategory" =>
                             { "operator" => [ "set_fixed_to", "set_mandatory" ],
                               "set_fixed_to" => subcats.keys.map(&:to_s),
                               "set_mandatory" => "true" } }
          flow.active = true
          flow.stop_after_match = false
          flow.priority = 600
          flow.updated_by_id = 1
          flow.created_by_id = 1
          flow.changeable = false
        end
        cwf.save!

        subcats.each do |subcat, subtypes|
          perform = if subtypes.any?
            { "ticket.subtype" =>
                { "operator" => [ "set_fixed_to", "set_mandatory" ],
                  "set_fixed_to" => subtypes,
                  "set_mandatory" => "true"
                }
            }
          else
            { "ticket.subtype" => { "operator" => [ "set_fixed_to", "set_readonly" ], "set_fixed_to" => [ "" ], "set_readonly" => "true" } }
          end

          CoreWorkflow.find_or_initialize_by(name: "ops - subcategory - #{cwf.id} - #{subcat} - visible options").tap do |flow|
            flow.object = "Ticket"
            flow.preferences = { "screen" => [ "create_middle", "edit" ] }
            flow.condition_saved = {}
            flow.condition_selected = { "ticket.category" => { "operator" => "is", "value" => [ cat_value.to_s ] },
                                        "ticket.subcategory" => { "operator" => "is", "value" => [ subcat.to_s ] } }
            flow.perform = perform
            flow.priority = 700
            flow.updated_by_id = 1
            flow.created_by_id = 1
            flow.changeable = false
          end.save!
        end
      end

      CoreWorkflow.find_or_initialize_by(name: 'ops - ticket - triage process finalisation').tap do |flow|
        flow.object = "Ticket"
        flow.preferences = { "screen" => [ "edit" ] }
        flow.condition_saved = {
          "ticket.origin" => { "operator" => "is", "value" => [ "portal" ] },
          "ticket.process_type" => { "operator" => "is", "value" => [ "portal_issue_triage" ] },
        }
        flow.condition_selected = {
          "ticket.ops_state" => { "operator" => "is", "value" => [ "sent_to_responsible" ] },
        }
        flow.perform = {
          "ticket.body" => { "operator" => "set_mandatory", "set_mandatory" => "true" },
          "ticket.responsible_subject" => { "operator" => "set_mandatory", "set_mandatory" => "true" },
        }
        flow.active = true
        flow.stop_after_match = false
        flow.changeable = true
        flow.priority = 159
        flow.updated_by_id = 1
        flow.created_by_id = 1
      end.save!

      CoreWorkflow.find_or_initialize_by(name: 'ops - ticket - verification process closed set readonly attributes').tap do |flow|
        flow.object = "Ticket"
        flow.preferences = { "screen" => [ "edit" ] }
        flow.condition_saved =  {
          "ticket.ops_state" => { "operator" => "is", "value" => [ "accepted", "rejected" ] },
          "ticket.process_type" => { "operator" => "is", "value" => ["portal_issue_verification"]},
          "ticket.origin" => { "operator" => "is", "value" => ["portal"]}
        }
        flow.condition_selected = {}
        flow.perform = {
          "ticket.issue_resolved" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.ops_state" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.process_type" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.group_id" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.owner_id" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.title" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.priority_id" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.issue_type" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.state_id" => { "operator" => "set_readonly", "set_readonly" => "true" }
        }
        flow.active = true
        flow.stop_after_match = false
        flow.changeable = true
        flow.priority = 160
        flow.updated_by_id = 1
        flow.created_by_id = 1
      end.save!

      CoreWorkflow.find_or_initialize_by(name: 'ops - ticket - triage process closed set readonly attributes').tap do |flow|
        flow.object = "Ticket"
        flow.preferences = { "screen" => [ "edit" ] }
        flow.condition_saved =  {
          "ticket.state_id" => { "operator" => "is", "value" => [ Ticket::State.find_by(name: "closed").id ] },
          "ticket.process_type" => { "operator" => "is", "value" => ["portal_issue_triage"]},
          "ticket.origin" => { "operator" => "is", "value" => ["portal"]}
        }
        flow.condition_selected = {}
        flow.perform = {
          "ticket.body" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.responsible_subject" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.ops_state" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.process_type" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.responsible_subject_changed_at" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.category" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.subcategory" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.subtype" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.address_municipality" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.address_state" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.address_county" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.address_street" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.address_house_number" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.address_postcode" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.address_lat" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.address_lon" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.group_id" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.owner_id" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.title" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.priority_id" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.issue_type" => { "operator" => "set_readonly", "set_readonly" => "true" }
        }
        flow.active = true
        flow.stop_after_match = false
        flow.changeable = true
        flow.priority = 160
        flow.updated_by_id = 1
        flow.created_by_id = 1
      end.save!

      CoreWorkflow.find_or_initialize_by(name: 'ops - disallow all users to change ticket owner if set already').tap do |flow|
        flow.object = "Ticket"
        flow.preferences = { "screen" => [ "edit" ] }
        flow.condition_saved = {
          "ticket.owner_id" => { "operator" => "is set" }
        }
        flow.condition_selected = {}
        flow.perform = {
          "ticket.owner_id" => { "operator" => "set_readonly", "set_readonly" => "true" }
        }
        flow.active = true
        flow.stop_after_match = false
        flow.changeable = true
        flow.priority = 185
        flow.updated_by_id = 1
        flow.created_by_id = 1
      end.save!

      CoreWorkflow.find_or_initialize_by(name: 'ops - allow admins to change ticket owner').tap do |flow|
        flow.object = "Ticket"
        flow.preferences = { "screen" => [ "edit" ] }
        flow.condition_saved = {}
        flow.condition_selected = {
          "session.role_ids" => { "operator" => "is", "value" => [
            Role.find_by(name: 'Admin').id,
            Role.find_by(name: 'Administrátor dobrovoľníkov').id
          ]}
        }
        flow.perform = {
          "ticket.owner_id" => { "operator" => "unset_readonly", "unset_readonly" => "true" }
        }
        flow.active = true
        flow.stop_after_match = false
        flow.changeable = true
        flow.priority = 190
        flow.updated_by_id = 1
        flow.created_by_id = 1
      end.save!

      CoreWorkflow.find_or_initialize_by(name: 'ops - make everything readonly if ticket is archived').tap do |flow|
        flow.object = "Ticket"
        flow.preferences = { "screen" => [ "edit" ] }
        flow.condition_saved = {
          "ticket.ops_state" => { "operator" => "is", "value" => [ "archived" ] }
        }
        flow.condition_selected = {}
        flow.perform = {
          "ticket.body" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.responsible_subject" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.ops_state" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.state_id" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.process_type" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.responsible_subject_changed_at" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.category" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.subcategory" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.subtype" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.address_municipality" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.address_state" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.address_county" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.address_street" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.address_house_number" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.address_postcode" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.address_lat" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.address_lon" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.group_id" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.owner_id" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.title" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.priority_id" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.issue_type" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.investment" => { "operator" => "set_readonly", "set_readonly" => "true" },
        }
        flow.active = true
        flow.stop_after_match = false
        flow.changeable = true
        flow.priority = 160
        flow.updated_by_id = 1
        flow.created_by_id = 1
      end.save!

      CoreWorkflow.find_or_initialize_by(name: 'OPS - Zobraz odkaz na kataster ak existujú koordináty').tap do |flow|
        flow.object = "Ticket"
        flow.preferences = { "screen" => [ "edit" ] }
        flow.condition_saved = {
          "ticket.address_lat" => { "operator" => "is set", "value" => "" },
          "ticket.address_lon" => { "operator" => "is set", "value" => "" }
        }
        flow.condition_selected = {}
        flow.perform = {
          "ticket.zbgis_link" => {
            "operator" => ["show", "set_readonly"],
            "show" => "true",
            "set_readonly" => "true"
          }
        }
        flow.active = true
        flow.stop_after_match = false
        flow.changeable = true
        flow.priority = 250
        flow.updated_by_id = 1
        flow.created_by_id = 1
      end.save!

      CoreWorkflow.find_or_initialize_by(name: 'ops - ticket - duplicate - set attributes').tap do |flow|
        flow.object = "Ticket"
        flow.preferences = { "screen" => [ "edit" ] }
        flow.condition_saved = {
        }
        flow.condition_selected = {
          "ticket.ops_state" => { "operator" => "is", "value" => "duplicate" }
        }
        flow.perform = {
          "ticket.title" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.body" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.address_municipality" => { "operator" => "hide", "hide" => "true" },
          "ticket.address_state" => { "operator" => "hide", "hide" => "true" },
          "ticket.address_county" => { "operator" => "hide", "hide" => "true" },
          "ticket.address_street" => { "operator" => "hide", "hide" => "true" },
          "ticket.address_house_number" => { "operator" => "hide", "hide" => "true" },
          "ticket.address_postcode" => { "operator" => "hide", "hide" => "true" },
          "ticket.investment" => { "operator" => "hide", "hide" => "true" },
          "ticket.likes_count" => { "operator" => "hide", "hide" => "true" },
          "ticket.priority_id" => { "operator" => "hide", "hide" => "true" },
          "ticket.portal_url" => { "operator" => "hide", "hide" => "true" },
          "ticket.responsible_subject_changed_at" => { "operator" => "hide", "hide" => "true" },
          "ticket.responsible_subject" => { "operator" => "hide", "hide" => "true" },
          "ticket.zbgis_link" => { "operator" => "hide", "hide" => "true" },
          "ticket.address_lat" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.address_lon" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.issue_type" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.category" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.subcategory" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.subtype" => { "operator" => "set_readonly", "set_readonly" => "true" }
        }
        flow.active = true
        flow.stop_after_match = false
        flow.changeable = true
        flow.priority = 300
        flow.updated_by_id = 1
        flow.created_by_id = 1
      end.save!

      # deactivate predefined triggers
      Trigger.find_by(name: 'auto reply (on new tickets)')&.update!(active: false)

      # create triggers
      Trigger.find_or_initialize_by(name: "150 - Zmena stavu na v riešení pri odpovedi").tap do |trigger|
        trigger.condition = {
          "operator" => "AND",
          "conditions" => [
            { "name" => "article.action", "operator" => "is", "value" => "create" },
            { "name" => "ticket.action", "operator" => "is not", "value" => "create" },
            { "name" => "ticket.process_type", "operator" => "is", "value" => [ "portal_issue_resolution" ] },
            { "name" => "ticket.ops_state", "operator" => "is", "value" => [ "unresolved", "sent_to_responsible" ] },
            { "name" => "article.internal", "operator" => "is", "value" => [ "false" ] },
            { "name" => "article.sender_id", "operator" => "is", "value" => [ "2" ] },
            { "name" => "article.type_id", "operator" => "is", "value" => [ Ticket::Article::Type.find_by(name: 'note').id.to_s, Ticket::Article::Type.find_by(name: 'email').id.to_s ] }
          ]
        }
        trigger.perform = {
          "ticket.ops_state" => { "value" => "in_progress" },
          "ticket.state_id" => { "value" => Ticket::State.find_by(name: 'open').id.to_s }
        }
        trigger.activator = "action"
        trigger.execution_condition_mode = "selective"
        trigger.active = true
        trigger.updated_by_id = 1
        trigger.created_by_id = 1
      end.save!

      Trigger.find_or_initialize_by(name: "151 - Zmena stavu na v riešení pri odpovedi - webhook zodpovedný subjekt").tap do |trigger|
        trigger.condition = {
          "operator" => "AND",
          "conditions" => [
            { "name" => "article.action", "operator" => "is", "value" => "create" },
            { "name" => "ticket.action", "operator" => "is not", "value" => "create" },
            { "name" => "ticket.process_type", "operator" => "is", "value" => [ "portal_issue_resolution" ] },
            { "name" => "article.internal", "operator" => "is", "value" => [ "false" ] },
            { "name" => "article.sender_id", "operator" => "is", "value" => [ "2" ] },
            { "name" => "article.type_id", "operator" => "is", "value" => [ Ticket::Article::Type.find_by(name: 'note').id.to_s, Ticket::Article::Type.find_by(name: 'email').id.to_s ] }
          ]
        }
        trigger.perform = {
          "notification.webhook" => { "webhook_id" => Webhook.find_by(name: "OPS - Upravený podnet pre zodpovedný subjekt").id }
        }
        trigger.activator = "action"
        trigger.execution_condition_mode = "selective"
        trigger.active = true
        trigger.updated_by_id = 1
        trigger.created_by_id = 1
      end.save!

      Trigger.find_or_initialize_by(name: "151 - Zmena stavu na v riešení pri odpovedi - webhook portál").tap do |trigger|
        trigger.condition = {
          "operator" => "AND",
          "conditions" => [
            { "name" => "article.action", "operator" => "is", "value" => "create" },
            { "name" => "ticket.action", "operator" => "is not", "value" => "create" },
            { "name" => "ticket.process_type", "operator" => "is", "value" => [ "portal_issue_resolution" ] },
            { "name" => "article.internal", "operator" => "is", "value" => [ "false" ] },
            { "name" => "article.sender_id", "operator" => "is", "value" => [ "2" ] },
            { "name" => "article.type_id", "operator" => "is", "value" => [ Ticket::Article::Type.find_by(name: 'note').id.to_s, Ticket::Article::Type.find_by(name: 'email').id.to_s ] }
          ]
        }
        trigger.perform = {
          "notification.webhook" => { "webhook_id" => Webhook.find_by(name: "OPS - Upravený podnet pre OPS portál").id }
        }
        trigger.activator = "action"
        trigger.execution_condition_mode = "selective"
        trigger.active = true
        trigger.updated_by_id = 1
        trigger.created_by_id = 1
      end.save!

      Trigger.find_or_initialize_by(name: '200 - ops - preposielanie - VZOR - <subjekt> - nový podnet').tap do |trigger|
        trigger.condition = {
          "operator" => "AND",
          "conditions" => [
            { "name" => "ticket.process_type", "operator" => "is", "value" => "portal_issue_resolution" },
            { "name" => "ticket.issue_type", "operator" => "is", "value" => [ "issue", "question" ] },
            { "name" => "ticket.responsible_subject", "operator" => "is", "value" => [ { "label" => "Vzor", "value" => 0 } ] },
            { "operator" => "OR", "conditions" => [
              { "name" => "ticket.action", "operator" => "is", "value" => "create" },
              { "name" => "ticket.responsible_subject", "operator" => "has changed", "value" => [] }
            ] }
          ]
        }
        trigger.perform = {
          "notification.email" => {
            "body" => "<div>Správca podnetu na portáli Odkaz pre starostu vám priradil podnet.</div><div><br></div><div><b>Názov podnetu:</b>&nbsp;\#{ticket.title}<br><br><div></div><div><b>Adresa:</b>&nbsp;\#{ticket.address_municipality} - \#{ticket.address_street}</div><div><b>Text podnetu:</b></div><div>\#{ticket.body}<br><br>Odkaz na portál:&nbsp;\#{ticket.portal_url} <br><br><div></div><div><i>Reagovať na túto správu môžete odpoveďou na tento email.</i></div></div>",
            "internal" => "true",
            "recipient" => [ "userid_#{template_external_responsible_subject_user.id}" ],
            "subject" => "Odkaz pre starostu - \#{ticket.title}",
            "include_attachments" => "true"
          }
        }
        trigger.activator = "action"
        trigger.execution_condition_mode = "selective"
        trigger.active = false
        trigger.updated_by_id = 1
        trigger.created_by_id = 1
      end.save!

      Trigger.find_or_initialize_by(name: '200 - ops - preposielanie - VZOR - <subjekt> - nová verejná pochvala').tap do |trigger|
        trigger.condition = {
          "operator" => "AND",
          "conditions" => [
            { "name" => "ticket.process_type", "operator" => "is", "value" => "portal_issue_triage" },
            { "name" => "ticket.issue_type", "operator" => "is", "value" => [ "praise" ] },
            { "name" => "ticket.responsible_subject", "operator" => "is", "value" => [ { "label" => "Vzor", "value" => 0 } ] },
            { "name" => "ticket.ops_state", "operator" => "is", "value" => [ "resolved" ] },
            { "name" => "ticket.ops_state", "operator" => "has changed", "value" => [] },
          ]
        }
        trigger.perform = {
          "notification.email" => {
            "body" => "<div>Na portáli Odkaz pre starostu vám bola adresovaná verejná pochvala.</div><div><br></div><div><b>Názov:</b>&nbsp;\#{ticket.title}<br><br><div></div><div><b>Text pochvaly:</b></div><div>\#{ticket.body}<br><br>Odkaz na portál:&nbsp;\#{ticket.portal_url} <br><br><div></div><div><i>Na pochvalu nie je možné odpovedať.</i></div></div>",
            "internal" => "true",
            "recipient" => [ "userid_#{template_external_responsible_subject_user.id}" ],
            "subject" => "Odkaz pre starostu - Pochvala \#{ticket.title}",
            "include_attachments" => "true"
          }
        }
        trigger.activator = "action"
        trigger.execution_condition_mode = "selective"
        trigger.active = false
        trigger.updated_by_id = 1
        trigger.created_by_id = 1
      end.save!

      Trigger.find_or_initialize_by(name: '200 - ops - preposielanie - VZOR - <subjekt> - nová neverejná pochvala').tap do |trigger|
        trigger.condition = {
          "operator" => "AND",
          "conditions" => [
            { "name" => "ticket.process_type", "operator" => "is", "value" => "portal_issue_triage" },
            { "name" => "ticket.issue_type", "operator" => "is", "value" => [ "praise" ] },
            { "name" => "ticket.responsible_subject", "operator" => "is", "value" => [ { "label" => "Vzor", "value" => 0 } ] },
            { "name" => "ticket.ops_state", "operator" => "is", "value" => [ "unresolved" ] },
            { "name" => "ticket.ops_state", "operator" => "has changed", "value" => [] },
          ]
        }
        trigger.perform = {
          "notification.email" => {
            "body" => "<div>Na portáli Odkaz pre starostu vám bola adresovaná neverejná pochvala.</div><div><br></div><div><b>Názov:</b>&nbsp;\#{ticket.title}<br><br><div></div><div><b>Text pochvaly:</b></div><div>\#{ticket.body}<br><br><div></div><div><i>Na pochvalu nie je možné odpovedať.</i></div></div>",
            "internal" => "true",
            "recipient" => [ "userid_#{template_external_responsible_subject_user.id}" ],
            "subject" => "Odkaz pre starostu - Pochvala \#{ticket.title}",
            "include_attachments" => "true"
          }
        }
        trigger.activator = "action"
        trigger.execution_condition_mode = "selective"
        trigger.active = false
        trigger.updated_by_id = 1
        trigger.created_by_id = 1
      end.save!

      Trigger.find_or_initialize_by(name: '200 - ops - preposielanie - VZOR - <subjekt> - komentáre z portálu').tap do |trigger|
        trigger.condition = {
          "ticket.process_type" => { "operator" => "is", "value" => "portal_issue_resolution" },
          "ticket.issue_type" => { "operator" => "is", "value" => [ "issue", "question" ] },
          "ticket.responsible_subject" => { "operator" => "is", "value_completion" => "", "value" => [ { "label" => "Vzor", "value" => 0 } ] },
          "article.action" => { "operator" => "is", "value" => "create" },
          "article.internal" => { "operator" => "is", "value" => [ "false" ] },
          "article.sender_id" => { "operator" => "is", "value" => [ Ticket::Article::Sender.find_by_name("Customer").id ] },
          "article.type_id" => { "operator" => "is not", "value" => [ Ticket::Article::Type.find_by_name("email").id ] },
        }
        trigger.perform = {
          "notification.email" => {
            "body" => "<div>K podnetu na portáli <b>Odkaz pre starostu</b> bol pridaný komentár od používateľa. Môžete na neho reagovať odpovedaním na tento email.</div><div><br></div><div><b>Obsah komentára:</b></div><div>\#{article.body_as_html}<br><br>Odkaz na portál:&nbsp;\#{ticket.portal_url} <br><br><div></div><div><i>Reagovať na túto správu môžete odpoveďou na tento email.</i></div></div>",
            "internal" => "true",
            "recipient" => [ "userid_#{template_external_responsible_subject_user.id}" ],
            "subject" => "Odkaz pre starostu - \#{ticket.title}",
            "include_attachments" => "true"
          }
        }
        trigger.activator = "action"
        trigger.execution_condition_mode = "selective"
        trigger.active = false
        trigger.updated_by_id = 1
        trigger.created_by_id = 1
      end.save!

      Trigger.find_or_initialize_by(name: '200 - ops - preposielanie - VZOR - <subjekt> - komentáre z triáže').tap do |trigger|
        trigger.condition = {
          "ticket.process_type" => { "operator" => "is", "value" => "portal_issue_resolution" },
          "ticket.issue_type" => { "operator" => "is", "value" => [ "issue", "question" ] },
          "ticket.responsible_subject" => { "operator" => "is", "value_completion" => "", "value" => [ { "label" => "Test", "value" => 0 } ] },
          "article.action" => { "operator" => "is", "value" => "create" },
          "article.internal" => { "operator" => "is", "value" => [ "false" ] },
          "article.sender_id" => { "operator" => "is", "value" => [ Ticket::Article::Sender.find_by_name("Agent").id ] },
          "article.body" => { "operator" => "contains", "value" => "[[pre zodpovedny subjekt]]" }
        }
        trigger.perform = {
          "notification.email" => {
            "body" => "<div>Správca podnetu na portáli Odkaz pre starostu vám posiela novú správu.</div><div><br></div><div><b>Obsah správy:</b></div><div>\#{article.body_as_html}<br><br>Odkaz na portál:&nbsp;\#{ticket.portal_url} <br><br><div></div><div><i>Reagovať na túto správu môžete odpoveďou na tento email.</i></div></div>",
            "internal" => "true",
            "recipient" => [ "userid_#{template_external_responsible_subject_user.id}" ],
            "subject" => "Odkaz pre starostu - \#{ticket.title}",
            "include_attachments" => "true"
          }
        }
        trigger.activator = "action"
        trigger.execution_condition_mode = "selective"
        trigger.active = false
        trigger.updated_by_id = 1
        trigger.created_by_id = 1
      end.save!

      Trigger.find_or_initialize_by(name: '200 - ops - preposielanie nových podnetov PRO zodpovedným subjektom').tap do |trigger|
        trigger.condition = {
          "operator" => "AND", "conditions" => [
            { "name" => "ticket.process_type", "operator" => "is", "value" => [ "portal_issue_resolution" ] },
            { "name" => "ticket.issue_type", "operator" => "is", "value" => [ "issue", "question" ] },
            { "name" => "ticket.responsible_subject", "operator" => "is", "value" => [ { "label" => "Vzor", "value" => 0 } ] },
            { "name" => "ticket.ops_state", "operator" => "is", "value" => [ "sent_to_responsible" ] },
            { "operator" => "OR", "conditions" => [
              { "name" => "ticket.action", "operator" => "is", "value" => "create" },
              { "name" => "ticket.responsible_subject", "operator" => "has changed", "value" => [] }
            ]}
          ]
        }
        trigger.perform = {
          "notification.webhook" => { "webhook_id" => Webhook.find_by(name: "OPS - Nový podnet pre zodpovedný subjekt").id }
        }
        trigger.activator = "action"
        trigger.execution_condition_mode = "selective"
        trigger.active = true
        trigger.updated_by_id = 1
        trigger.created_by_id = 1
      end.save! unless Trigger.exists?(name: '200 - ops - preposielanie nových podnetov PRO zodpovedným subjektom')

      Trigger.find_or_initialize_by(name: '200 - ops - preposielanie novej pochvaly PRO zodpovedným subjektom').tap do |trigger|
        trigger.condition = {
          "operator" => "AND", "conditions" => [
            { "name" => "ticket.process_type", "operator" => "is", "value" => [ "portal_issue_triage" ] },
            { "name" => "ticket.issue_type", "operator" => "is", "value" => [ "praise" ] },
            { "name" => "ticket.responsible_subject", "operator" => "is", "value" => [ { "label" => "Vzor", "value" => 0 } ] },
            { "name" => "ticket.ops_state", "operator" => "is", "value" => [ "resolved", "unresolved" ] },
            { "name" => "ticket.ops_state", "operator" => "has changed", "value" => [] },
          ]
        }
        trigger.perform = {
          "notification.webhook" => { "webhook_id" => Webhook.find_by(name: "OPS - Nový podnet pre zodpovedný subjekt").id }
        }
        trigger.activator = "action"
        trigger.execution_condition_mode = "selective"
        trigger.active = true
        trigger.updated_by_id = 1
        trigger.created_by_id = 1
      end.save! unless Trigger.exists?(name: '200 - ops - preposielanie novej pochvaly PRO zodpovedným subjektom')

      Trigger.find_or_initialize_by(name: '200 - ops - preposielanie upravených podnetov PRO zodpovedným subjektom').tap do |trigger|
        trigger.condition = {
          "operator" => "AND", "conditions" => [
            { "name" => "ticket.process_type", "operator" => "is", "value" => [ "portal_issue_resolution" ] },
            { "name" => "ticket.issue_type", "operator" => "is", "value" => [ "issue", "question" ] },
            { "name" => "ticket.responsible_subject", "operator" => "is", "value" => [ { "label" => "Vzor", "value" => 0 } ] },
            { "operator" => "OR", "conditions" => [
              { "name" => "ticket.title", "operator" => "has changed" },
              { "name" => "ticket.ops_state", "operator" => "has changed", "value" => [] },
              { "name" => "ticket.issue_type", "operator" => "has changed", "value" => [] },
              { "name" => "ticket.responsible_subject", "operator" => "has changed" },
              { "name" => "ticket.category", "operator" => "has changed", "value" => [] },
              { "name" => "ticket.subcategory", "operator" => "has changed", "value" => [] },
              { "name" => "ticket.subtype", "operator" => "has changed", "value" => [] },
              { "name" => "ticket.address_municipality", "operator" => "has changed", "value" => [] },
              { "name" => "ticket.address_municipality_district", "operator" => "has changed", "value" => [] },
              { "name" => "ticket.address_street", "operator" => "has changed" },
              { "name" => "ticket.address_house_number", "operator" => "has changed" },
              { "name" => "ticket.address_postcode", "operator" => "has changed" },
              { "name" => "ticket.address_lat", "operator" => "has changed" },
              { "name" => "ticket.address_lon", "operator" => "has changed" },
              { "name" => "ticket.likes_count", "operator" => "has changed" },
              { "name" => "ticket.portal_url", "operator" => "has changed" },
            ]}
          ]
        }
        trigger.perform = {
          "notification.webhook" => { "webhook_id" => Webhook.find_by(name: "OPS - Upravený podnet pre zodpovedný subjekt").id }
        }
        trigger.activator = "action"
        trigger.execution_condition_mode = "selective"
        trigger.active = true
        trigger.updated_by_id = 1
        trigger.created_by_id = 1
      end.save! unless Trigger.exists?(name: '200 - ops - preposielanie upravených podnetov PRO zodpovedným subjektom')

      Trigger.find_or_initialize_by(name: '200 - ops - preposielanie nových komentárov PRO zodpovedným subjektom').tap do |trigger|
        trigger.condition = {
          "ticket.process_type" => { "operator" => "is", "value" => "portal_issue_resolution" },
          "ticket.issue_type" => { "operator" => "is", "value" => [ "issue", "question" ] },
          "ticket.responsible_subject" => { "operator" => "is", "value" => [ { "label" => "Vzor", "value" => 0 } ] },
          "ticket.ops_state" => { "operator" => "is", "value" => [ "unresolved", "referred", "marked_as_resolved", "closed", "in_progress", "resolved", "rejected", "sent_to_responsible" ] },
          "article.internal" => { "operator" => "is", "value" => false },
          "article.action" => { "operator" => "is", "value" => "create" },
          "ticket.action" => { "operator" => "is not", "value" => "create" },
        }
        trigger.perform = {
          "notification.webhook" => { "webhook_id" => Webhook.find_by(name: "OPS - Nový komentár pre zodpovedný subjekt").id }
        }
        trigger.activator = "action"
        trigger.execution_condition_mode = "selective"
        trigger.active = true
        trigger.updated_by_id = 1
        trigger.created_by_id = 1
      end.save! unless Trigger.exists?(name: '200 - ops - preposielanie nových komentárov PRO zodpovedným subjektom')

      Trigger.find_or_initialize_by(name: '900 - ops - nastavenie času poslednej zmeny zodpovedného subjektu').tap do |trigger|
        trigger.condition = {
          "operator" => "OR", "conditions" => [
            { "name" => "ticket.responsible_subject", "operator" => "has changed", "value" => [] },
            {
              "operator" => "AND", "conditions" => [
                { "name" => "ticket.action", "operator" => "is", "value" => "create" },
                { "name" => "ticket.process_type", "operator" => "is", "value" => [ "portal_issue_resolution" ] }
              ]
            },
            {
              "operator" => "AND", "conditions" => [
                { "name" => "ticket.ops_state", "operator" => "has changed", "value" => [] },
                { "name" => "ticket.ops_state", "operator" => "is", "value" => [ "sent_to_responsible" ] }
              ]
            }
          ]
        }
        trigger.perform = { "ticket.responsible_subject_changed_at" => { "operator" => "relative", "value" => "1", "range" => "minute" } }
        trigger.activator = "action"
        trigger.execution_condition_mode = "selective"
        trigger.active = true
        trigger.updated_by_id = 1
        trigger.created_by_id = 1
      end.save!

      Trigger.find_or_initialize_by(name: '200 - ops - preposielanie upravených podnetov na portál').tap do |trigger|
        trigger.condition = {
          "operator" => "AND", "conditions" => [
            { "name" => "ticket.origin", "operator" => "is", "value" => [ "portal" ] },
            { "operator" => "OR", "conditions" => [
              { "name" => "ticket.title", "operator" => "has changed" },
              { "name" => "ticket.body", "operator" => "has changed" },
              { "name" => "ticket.ops_state", "operator" => "has changed", "value" => [] },
              { "name" => "ticket.issue_resolved", "operator" => "has changed", "value" => [] },
              { "name" => "ticket.issue_type", "operator" => "has changed", "value" => [] },
              { "name" => "ticket.responsible_subject", "operator" => "has changed" },
              { "name" => "ticket.category", "operator" => "has changed", "value" => [] },
              { "name" => "ticket.subcategory", "operator" => "has changed", "value" => [] },
              { "name" => "ticket.subtype", "operator" => "has changed", "value" => [] },
              { "name" => "ticket.address_municipality", "operator" => "has changed", "value" => [] },
              { "name" => "ticket.address_municipality_district", "operator" => "has changed", "value" => [] },
              { "name" => "ticket.address_street", "operator" => "has changed" },
              { "name" => "ticket.address_house_number", "operator" => "has changed" },
              { "name" => "ticket.address_postcode", "operator" => "has changed" },
              { "name" => "ticket.address_lat", "operator" => "has changed" },
              { "name" => "ticket.address_lon", "operator" => "has changed" },
              { "name" => "ticket.investment", "operator" => "has changed", "value" => [] },
              { "name" => "ticket.portal_url", "operator" => "has changed" },
            ]}
          ]
        }
        trigger.perform = {
          "notification.webhook" => { "webhook_id" => Webhook.find_by(name: "OPS - Upravený podnet pre OPS portál").id }
        }
        trigger.activator = "action"
        trigger.execution_condition_mode = "selective"
        trigger.active = true
        trigger.updated_by_id = 1
        trigger.created_by_id = 1
      end.save!

      Trigger.find_or_initialize_by(name: '200 - ops - preposielanie nových komentárov na portál').tap do |trigger|
        trigger.condition = {
          "operator" => "AND", "conditions" => [
            { "name" => "ticket.origin", "operator" => "is", "value" => [ "portal" ] },
            { "operator" => "OR", "conditions" => [
              { "operator" => "AND", "conditions" => [
                { "name" => "ticket.process_type", "operator" => "is", "value" => [ "portal_issue_resolution" ] },
                { "name" => "ticket.issue_type", "operator" => "is", "value" => [ "issue", "question" ] },
                { "name" => "ticket.origin", "operator" => "is", "value" => [ "portal" ] },
                { "name" => "article.internal", "operator" => "is", "value" => "false" },
                { "name" => "article.body", "operator" => "contains", "value" => "[[ops portal]]" },
                { "name" => "article.action", "operator" => "is", "value" => "create" },
              ] },
              { "operator" => "AND", "conditions" => [
                { "name" => "ticket.process_type", "operator" => "is", "value" => [ "portal_issue_triage" ] },
                { "name" => "ticket.issue_type", "operator" => "is", "value" => [ "issue", "question" ] },
                { "name" => "ticket.state_id", "operator" => "is not", "value" => [ Ticket::State.find_by(name: "closed").id ] },
                { "name" => "ticket.origin", "operator" => "is", "value" => [ "portal" ] },
                { "name" => "article.internal", "operator" => "is", "value" => "false" },
                { "name" => "article.sender_id", "operator" => "is", "value" => [ Ticket::Article::Sender.find_by_name("Agent").id ] },
                { "name" => "article.action", "operator" => "is", "value" => "create" },
              ] }
            ] }
          ]
        }
        trigger.perform = {
          "notification.webhook" => { "webhook_id" => Webhook.find_by(name: "OPS - Nový komentár pre OPS portál").id }
        }
        trigger.activator = "action"
        trigger.execution_condition_mode = "selective"
        trigger.active = true
        trigger.updated_by_id = 1
        trigger.created_by_id = 1
      end.save!

      Trigger.find_or_initialize_by(name: '200 - ops - zmena stavu na označený za vyriešený pri značke z emailu').tap do |trigger|
        trigger.condition = {
          "operator" => "AND", "conditions" => [
            { "name" => "ticket.origin", "operator" => "is", "value" => [ "portal" ] },
            { "operator" => "AND", "conditions" => [
              { "name" => "ticket.process_type", "operator" => "is", "value" => [ "portal_issue_resolution" ] },
              { "name" => "ticket.issue_type", "operator" => "is", "value" => [ "issue", "question" ] },
              { "name" => "ticket.origin", "operator" => "is", "value" => [ "portal" ] },
              { "name" => "article.internal", "operator" => "is", "value" => "false" },
              { "name" => "article.action", "operator" => "is", "value" => "create" },
              { "operator" => "OR", "conditions" => [
                { "name" => "article.body", "operator" => "contains", "value" => "[[vyriesene]]" },
                { "name" => "article.body", "operator" => "contains", "value" => "[[vyrieseny]]" },
                { "name" => "article.body", "operator" => "contains", "value" => "[[vyriešené]]" },
                { "name" => "article.body", "operator" => "contains", "value" => "[[vyriešaný]]" },
              ] }
            ] }
          ]
        }
        trigger.perform = {
          "ticket.ops_state" => { "operator" => "set", "value" => "marked_as_resolved" },
          "notification.webhook" => { "webhook_id" => Webhook.find_by(name: "OPS - Upravený podnet pre OPS portál").id }
        }
        trigger.activator = "action"
        trigger.execution_condition_mode = "selective"
        trigger.active = true
        trigger.updated_by_id = 1
        trigger.created_by_id = 1
      end.save!

      Trigger.find_or_initialize_by(name: '200 - ops - zmena stavu na odstúpený pri značke z emailu').tap do |trigger|
        trigger.condition = {
          "operator" => "AND", "conditions" => [
            { "name" => "ticket.origin", "operator" => "is", "value" => [ "portal" ] },
            { "operator" => "AND", "conditions" => [
              { "name" => "ticket.process_type", "operator" => "is", "value" => [ "portal_issue_resolution" ] },
              { "name" => "ticket.issue_type", "operator" => "is", "value" => [ "issue", "question" ] },
              { "name" => "ticket.origin", "operator" => "is", "value" => [ "portal" ] },
              { "name" => "article.internal", "operator" => "is", "value" => "false" },
              { "name" => "article.action", "operator" => "is", "value" => "create" },
              { "operator" => "OR", "conditions" => [
                { "name" => "article.body", "operator" => "contains", "value" => "[[odstupene]]" },
                { "name" => "article.body", "operator" => "contains", "value" => "[[odstupeny]]" },
                { "name" => "article.body", "operator" => "contains", "value" => "[[odstúpené]]" },
                { "name" => "article.body", "operator" => "contains", "value" => "[[odstúpený]]" },
              ] }
            ] }
          ]
        }
        trigger.perform = {
          "ticket.ops_state" => { "operator" => "set", "value" => "referred" },
          "notification.webhook" => { "webhook_id" => Webhook.find_by(name: "OPS - Upravený podnet pre OPS portál").id }
        }
        trigger.activator = "action"
        trigger.execution_condition_mode = "selective"
        trigger.active = true
        trigger.updated_by_id = 1
        trigger.created_by_id = 1
      end.save!

      Trigger.find_or_initialize_by(name: '100 - ops - upozornenie na komentovanie uzavretých prijatých triážnych tiketov').tap do |trigger|
        trigger.condition = {
          "ticket.process_type" => { "operator" => "is", "value" => "portal_issue_triage" },
          "ticket.state_id" => { "operator" => "is", "value" => [ Ticket::State.find_by(name: "closed").id ] },
          "ticket.ops_state" => { "operator" => "is", "value" => [ "sent_to_responsible" ] },
          "article.action" => { "operator" => "is", "value" => "create" },
          "article.internal" => { "operator" => "is", "value" => "false" }
        }
        trigger.perform = {
          "article.note" => {
            "body" => "Tento tiket je už uzavretý a nahradený novým tiketom. Ak chcete pridať komentár, použite, prosím, nový tiket v odkazoch vpravo dole.",
            "internal" => "true",
            "subject" => "Komentár k uzavretému podnetu",
          }
        }
        trigger.activator = "action"
        trigger.execution_condition_mode = "selective"
        trigger.active = true
        trigger.updated_by_id = 1
        trigger.created_by_id = 1
      end.save!

      Trigger.find_or_initialize_by(name: '100 - ops - upozornenie pri novej verejnej pochvale').tap do |trigger|
        trigger.condition = {
          "ticket.process_type" => { "operator" => "is", "value" => "portal_issue_triage" },
          "ticket.action" => { "operator" => "is", "value" => "create" },
          "ticket.issue_type" => { "operator" => "is", "value" => [ "praise" ] },
          "ticket.portal_public" => { "operator" => "is", "value" => "true" },
        }
        trigger.perform = {
          "article.note" => {
            "body" => "<div>Pochvalu nie je možné komentovať. Ak je potrebné upraviť text pochvaly, upravte text vpravo vo \"Finálny text podnetu\".</div><div>Zadávateľ povolil zverejnenie pochvaly na portáli Odkaz pre starostu.</div><br><div>Ak chcete pochvalu zverejniť a odoslať zodpovednému subjektu, nastavte zodpovedný subjekt a vyberte stav \"Vyriešený\".</div><div>Ak chcete pochvalu chcete iba odoslať zodpovednému ale nezverejniť ju, vyberte stav \"Neriešený\".</div><div>Ak chcete pochvalu zamietnuť, vyberte stav \"Zamietnutý\".",
            "internal" => "true",
            "subject" => "Komentár k procesom pochvaly",
          }
        }
        trigger.activator = "action"
        trigger.execution_condition_mode = "selective"
        trigger.active = true
        trigger.updated_by_id = 1
        trigger.created_by_id = 1
      end.save!

      Trigger.find_or_initialize_by(name: '100 - ops - upozornenie pri novej neverejnej pochvale').tap do |trigger|
        trigger.condition = {
          "ticket.process_type" => { "operator" => "is", "value" => "portal_issue_triage" },
          "ticket.action" => { "operator" => "is", "value" => "create" },
          "ticket.issue_type" => { "operator" => "is", "value" => [ "praise" ] },
          "ticket.portal_public" => { "operator" => "is", "value" => "false" },
        }
        trigger.perform = {
          "article.note" => {
            "body" => "<div>Pochvalu nie je možné komentovať. Ak je potrebné upraviť text pochvaly, upravte text vpravo vo \"Finálny text podnetu\".</div><div>Zadávateľ nepovolil zverejnenie pochvaly na portáli Odkaz pre starostu.</div><br><div>Ak chcete pochvalu odoslať zodpovednému, nastavte zodpovedný subjekt a vyberte stav \"Neriešený\".</div><div>Ak chcete pochvalu zamietnuť, vyberte stav \"Zamietnutý\".</div>",
            "internal" => "true",
            "subject" => "Komentár k procesom pochvaly",
          }
        }
        trigger.activator = "action"
        trigger.execution_condition_mode = "selective"
        trigger.active = true
        trigger.updated_by_id = 1
        trigger.created_by_id = 1
      end.save!

      Trigger.find_or_initialize_by(name: '100 - ops - upozornenie na komentovanie uzavretých triážnych tiketov').tap do |trigger|
        trigger.condition = {
          "ticket.process_type" => { "operator" => "is", "value" => "portal_issue_triage" },
          "ticket.state_id" => { "operator" => "is", "value" => [ Ticket::State.find_by(name: "closed").id ] },
          "ticket.ops_state" => { "operator" => "is", "value" => [ "rejected", "duplicate" ] },
          "article.action" => { "operator" => "is", "value" => "create" },
          "article.internal" => { "operator" => "is", "value" => "false" }
        }
        trigger.perform = {
          "article.note" => {
            "body" => "Tento tiket je už uzavretý.",
            "internal" => "true",
            "subject" => "Komentár k uzavretému podnetu",
          }
        }
        trigger.activator = "action"
        trigger.execution_condition_mode = "selective"
        trigger.active = true
        trigger.updated_by_id = 1
        trigger.created_by_id = 1
      end.save!

      Trigger.find_or_initialize_by(name: '800 - ops - podnet označený za vyriešený - notifikácia').tap do |trigger|
        trigger.condition = {
          "operator" => "AND", "conditions" => [
            { "name" => "ticket.process_type", "operator" => "is", "value" => [ "portal_issue_resolution" ] },
            { "name" => "ticket.origin", "operator" => "is", "value" => [ "portal" ] },
            { "name" => "ticket.ops_state", "operator" => "is", "value" => [ "marked_as_resolved" ] },
            { "name" => "ticket.ops_state", "operator" => "has changed", "value" => [] },
            { "name" => "ticket.updated_by_id", "operator" => "is", "pre_condition" => "specific", "value" => [ tech_user.id ] },
          ]
        }
        trigger.perform = {
          "article.note" => {
            "body" => "Podnet bol označený za vyriešený a čaká na schválenie.",
            "internal" => "false",
            "subject" => "Označený za vyriešený",
            "sender" => "Customer"
          }
        }
        trigger.note = "NEMENIŤ - spúšťač používa špeciálne parametre, ktoré budú zmazané pri úprave spúšťača."
        trigger.activator = "action"
        trigger.execution_condition_mode = "selective"
        trigger.active = true
        trigger.updated_by_id = 1
        trigger.created_by_id = 1
      end.save!

      Trigger.find_or_initialize_by(name: '800 - ops - zmena zodpovedného subjektu na "Iný subjekt" - notifikácia').tap do |trigger|
        trigger.condition = {
          "operator" => "AND", "conditions" => [
            { "name" => "ticket.process_type", "operator" => "is", "value" => [ "portal_issue_resolution" ] },
            { "name" => "ticket.origin", "operator" => "is", "value" => [ "portal" ] },
            { "name" => "ticket.responsible_subject", "operator" => "has changed", "value" => [] },
            { "name" => "ticket.responsible_subject", "operator" => "is", "value" => [ { "label" => "Iný subjekt", "value" => ENV["OTHER_RESPONSIBLE_SUBJECT_ID"] } ] },
            { "name" => "ticket.updated_by_id", "operator" => "is", "pre_condition" => "specific", "value" => [ tech_user.id ] },
          ]
        }
        trigger.perform = {
          "article.note" => {
            "body" => "Zodpovedný subjekt bol úradníkom zmenený na \"Iný subjekt\".",
            "internal" => "false",
            "subject" => "Zmena zodpovednosti na Iný subjekt",
            "sender" => "Customer"
          }
        }
        trigger.note = "NEMENIŤ - spúšťač používa špeciálne parametre, ktoré budú zmazané pri úprave spúšťača."
        trigger.activator = "action"
        trigger.execution_condition_mode = "selective"
        trigger.active = true
        trigger.updated_by_id = 1
        trigger.created_by_id = 1
      end.save!

      Trigger.find_or_initialize_by(name: '800 - ops - zmena zodpovedného subjektu - notifikácia').tap do |trigger|
        trigger.condition = {
          "operator" => "AND", "conditions" => [
            { "name" => "ticket.process_type", "operator" => "is", "value" => [ "portal_issue_resolution" ] },
            { "name" => "ticket.origin", "operator" => "is", "value" => [ "portal" ] },
            { "name" => "ticket.responsible_subject", "operator" => "has changed", "value" => [] },
            { "name" => "ticket.responsible_subject", "operator" => "is not", "value" => [ { "label" => "Iný subjekt", "value" => ENV["OTHER_RESPONSIBLE_SUBJECT_ID"] } ] },
            { "name" => "ticket.updated_by_id", "operator" => "is", "pre_condition" => "specific", "value" => [ tech_user.id ] },
          ]
        }
        trigger.perform = {
          "article.note" => {
            "body" => "Zodpovedný subjekt bol zmenený úradníkom na iný subjekt.",
            "internal" => "false",
            "subject" => "Zmena zodpovedného subjektu úradníkom"
          }
        }
        trigger.note = "NEMENIŤ - spúšťač používa špeciálne parametre, ktoré budú zmazané pri úprave spúšťača."
        trigger.activator = "action"
        trigger.execution_condition_mode = "selective"
        trigger.active = true
        trigger.updated_by_id = 1
        trigger.created_by_id = 1
      end.save!

      Trigger.find_or_initialize_by(name: '800 - ops - zmena zodpovedného subjektu agentom - notifikácia').tap do |trigger|
        trigger.condition = {
          "operator" => "AND", "conditions" => [
            { "name" => "ticket.process_type", "operator" => "is", "value" => [ "portal_issue_resolution" ] },
            { "name" => "ticket.origin", "operator" => "is", "value" => [ "portal" ] },
            { "name" => "ticket.responsible_subject", "operator" => "has changed", "value" => [] },
            { "name" => "ticket.updated_by_id", "operator" => "is not", "pre_condition" => "specific", "value" => [ tech_user.id ] },
          ]
        }
        trigger.perform = {
          "article.note" => {
            "body" => "Zodpovedný subjekt bol zmenený agentom.",
            "internal" => "false",
            "subject" => "Zmena zodpovedného subjektu agentom"
          }
        }
        trigger.note = "NEMENIŤ - spúšťač používa špeciálne parametre, ktoré budú zmazané pri úprave spúšťača."
        trigger.activator = "action"
        trigger.execution_condition_mode = "selective"
        trigger.active = true
        trigger.updated_by_id = 1
        trigger.created_by_id = 1
      end.save!

      Job.find_or_initialize_by(name: "NEMENIŤ - Neriešený po 15 dňoch od preposlania").tap do |job|
        job.timeplan = {
          "days"=>{
            "Mon"=>true, "Tue"=>true, "Wed"=>true, "Thu"=>true, "Fri"=>true, "Sat"=>false, "Sun"=>false
          },
          "hours"=>{
            "0"=>false, "1"=>false, "2"=>false, "3"=>false, "4"=>false, "5"=>false, "6"=>false, "7"=>false, "8"=>false, "9"=>true, "10"=>false, "11"=>false, "12"=>false, "13"=>false, "14"=>false, "15"=>false, "16"=>false, "17"=>false, "18"=>false, "19"=>false, "20"=>false, "21"=>false, "22"=>false, "23"=>false
          },
          "minutes"=>{
            "0"=>true, "10"=>false, "20"=>false, "30"=>false, "40"=>false, "50"=>false
          }
        }
        job.object = "Ticket"
        job.condition = {
          "ticket.ops_state"=>{"operator"=>"is", "value"=>["sent_to_responsible"]},
          "ticket.state_id"=>{
            "operator"=>"is not",
            "value"=>[
              Ticket::State.find_by(name: "closed").id,
              Ticket::State.find_by(name: "merged").id,
            ]
          },
          "ticket.process_type"=>{"operator"=>"is", "value"=>["portal_issue_resolution"]},
          "ticket.responsible_subject_changed_at"=>{"operator"=>"before (relative)", "value"=>"15", "range"=>"day"}
        }
        job.perform = {
          "article.note"=>{
            "body"=>"[[ops portal]][[pre zodpovedny subjekt]]Zodpovedný subjekt nereagoval na podnet do 15 dní. Podnet bol označený ako neriešený.",
            "internal"=>"false",
            "subject"=>"Neriešený podnet",
            "sender" => "Agent"
          },
          "ticket.ops_state"=>{"value"=> "unresolved"}
        }
        job.disable_notification = false
        job.localization = "system"
        job.timezone = "system"
        job.note = "NEMENIŤ! Ak zodpovedný subjekt neodpovie na nový podnet do 15 dní, podnet sa označí ako neriešený a odošle sa notifikácia zodpovednému subjektu aj portálu.",
        job.active = true
        job.updated_by_id = 1
        job.created_by_id = 1
      end.save!

      TextModule.create_or_update(
        name: "Správa pre zodpovedný subjekt",
        keywords: "zodpovedny",
        content: "[[pre zodpovedny subjekt]]<div><br></div><div>Tento podnet...</div>",
        note: "",
        active: true,
        updated_by_id: 1,
        created_by_id: 1,
      )

      TextModule.create_or_update(
        name: "Správa pre portál odkazu pre starostu",
        keywords: "ops,portal,zakaznik",
        content: "[[ops portal]]<div><br></div><div>Tento podnet...</div>",
        note: "",
        active: true,
        updated_by_id: 1,
        created_by_id: 1,
      )

      Scheduler.create_or_update(
        name:          'OPS - add all groups to tech role.',
        method:        'Ops::AssignTechRoleToAllGroupsJob.perform_now',
        period:        15.minutes,
        last_run:      Time.zone.now,
        prio:          2,
        active:        true,
        updated_by_id: 1,
        created_by_id: 1,
      )
    end
  end
end

Rake::Task['db:migrate'].enhance do
  Rake::Task['ops:triage:migrate'].execute
end

Rake::Task['db:seed'].enhance do
  Rake::Task['ops:triage:migrate'].execute
end
