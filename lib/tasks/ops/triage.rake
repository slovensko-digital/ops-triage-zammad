OPS_OLD_CATEGORIES_MAP = {
  "_5" => "Automobily(parkovanie, dlhodobo odstavené vozidlá)",
  "_1" => "Cesty a chodníky(cesty, cyklotrasy, schody, oplotenie)",
  "_3" => "Dopravné značenie (značky, semafory, stĺpiky)",
  "_4" => "Mestský mobiliár(koše, ihriská, lavičky, zastávky MHD)",
  "_6" => "Verejné služby(osvetlenie, kanalizácia, MHD, web, rozvodné siete)",
  "_7" => "Verejný poriadok(stavby, reklama, vandalizmus)",
  "_2" => "Zeleň a životné prostredie(stromy, neporiadok, znečisťovanie)"
}

OPS_CATEGORIES_MAP = {
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
    "vandalizmus": [ "rušenie nočného pokoja", "pitie alkoholu na verejnom priestore" ]
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
    "mŕtvy živočích": []
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
  "Iné": {
    "iné": []
  }
}

namespace :ops do
  namespace :triage do
    desc "Migrates triage environment"
    task migrate: :environment do
      next unless User.any?

      puts "Migrating triage environment..."
      Setting.set('user_create_account', false) # Disable user creation via web interface
      Setting.set('api_password_access', false) # Disable password access to REST API

      Setting.set('auth_third_party_auto_link_at_inital_login', true)
      Setting.set('auth_third_party_no_create_user', true)

      Setting.set('customer_ticket_create', false) # disable WEB interface ticket creation

      # create role for OPS users
      ops_user_role = Role.find_or_initialize_by(name: 'OPS User') do |role|
        role.note = __('OPS Portal users.')
        role.default_at_signup = false
        role.preferences = {}
        role.updated_by_id = 1
        role.created_by_id = 1
      end
      ops_user_role.save!

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
            'ticket.agent' => { shown: true },
          },
        },
        position: 1000,
        created_by_id: 1,
        updated_by_id: 1,
      )

      ObjectManager::Attribute.add(
        object: 'Ticket',
        name: 'issue_type',
        display: __('Typ podnetu'),
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
            'ticket.customer' => { shown: true },
            'ticket.agent' => { shown: true }
          },
          edit: {
            'ticket.customer' => { shown: true },
            'ticket.agent' => { shown: true }
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
          options: OPS_OLD_CATEGORIES_MAP.map { |k, v| { "name": v.to_s, "value": k.to_s } } +
            OPS_CATEGORIES_MAP.keys.map { |k| { "name": k.to_s, "value": k.to_s } },
          customsort: 'on',
          default: '',
          null: true,
          nulloption: true,
          maxlength: 255,
        },
        active: true,
        screens: {
          create_middle: {
            'ticket.customer' => { shown: true },
            'ticket.agent' => { shown: true }
          },
          edit: {
            'ticket.customer' => { shown: true },
            'ticket.agent' => { shown: true }
          }
        },
        position: 17,
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
            'ticket.customer' => { shown: true },
            'ticket.agent' => { shown: true }
          },
          edit: {
            'ticket.customer' => { shown: true },
            'ticket.agent' => { shown: true }
          }
        },
        position: 19,
        created_by_id: 1,
        updated_by_id: 1
      )

      subsubcategory_names = OPS_CATEGORIES_MAP.values.flat_map { |v| v.values }.flatten.uniq - [ "" ]
      ObjectManager::Attribute.add(
        object: 'Ticket',
        name: 'subcategory_type',
        display: __('Typ Problému'),
        data_type: 'select',
        data_option: {
          options: subsubcategory_names.map { |v| { name: v, value: v } },
          customsort: 'on',
          default: '',
          null: true,
          nulloption: true,
          maxlength: 255,
        },
        active: true,
        screens: {
          create_middle: {
            'ticket.customer' => { shown: true },
            'ticket.agent' => { shown: true }
          },
          edit: {
            'ticket.customer' => { shown: true },
            'ticket.agent' => { shown: true }
          }
        },
        position: 20,
        created_by_id: 1,
        updated_by_id: 1
      )

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
            'ticket.agent' => { shown: true },
            'ticket.customer' => { shown: true },
          },
          create_middle: {
            'ticket.agent' => { shown: true },
            'ticket.customer' => { shown: true },
          }
        },
        position: 100,
        created_by_id: 1,
        updated_by_id: 1,
      )

      ObjectManager::Attribute.migration_execute

      # add ops flows
      CoreWorkflow.find_or_initialize_by(name: 'ops - read-only ticket attributes').tap do |flow|
        flow.object = "Ticket"
        flow.preferences = { "screen" => [ "create_middle", "edit" ] }
        flow.condition_saved = {}
        flow.condition_selected = {}
        flow.perform = {
          "ticket.process_type" => { "operator" => "set_readonly", "set_readonly" => "true" },
          "ticket.likes_count" => { "operator" => "set_readonly", "set_readonly" => "true" }
        }
        flow.active = true
        flow.stop_after_match = false
        flow.changeable = true # TODO consider hiding from end users
        flow.priority = 100
        flow.updated_by_id = 1
        flow.created_by_id = 1
      end.save!

      CoreWorkflow.find_or_initialize_by(name: 'ops - likes_count visible only for ops issues').tap do |flow|
        flow.object = "Ticket"
        flow.preferences = { "screen" => [ "create_middle", "edit" ] }
        flow.condition_saved = {}
        flow.condition_selected = { "ticket.issue_type" => { "operator" => "not set", "value" => [ "issue", "question", "praise" ] } }
        flow.perform = { "ticket.likes_count" => { "operator" => "hide", "hide" => "true" } }
        flow.active = true
        flow.stop_after_match = false
        flow.changeable = true
        flow.priority = 500
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
        flow.perform = { "ticket.subcategory_type" => { "operator" => [ "set_fixed_to", "select" ], "set_fixed_to" => [ "" ], "select" => "" } }
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
        CoreWorkflow.find_or_initialize_by(name: "ops - category - #{cat} - visible options").tap do |flow|
          flow.object = "Ticket"
          flow.preferences = { "screen" => [ "create_middle", "edit" ] }
          flow.condition_saved = {}
          flow.condition_selected = { "ticket.category" => { "operator" => "is", "value" => [ cat.to_s ] } }
          flow.perform = { "ticket.subcategory" =>
                             { "operator" => [ "set_fixed_to", "set_mandatory" ],
                               "set_fixed_to" => [ "" ] + subcats.keys.map(&:to_s),
                               "set_mandatory" => "true" } }
          flow.active = true
          flow.stop_after_match = false
          flow.changeable = true
          flow.priority = 700
          flow.updated_by_id = 1
          flow.created_by_id = 1
          flow.changeable = false
        end.save!

        subcats.each do |subcat, subcat_types|
          perform = if subcat_types.any?
            { "ticket.subcategory_type" =>
                { "operator" => [ "set_fixed_to", "set_mandatory" ],
                  "set_fixed_to" => [ "" ] + subcat_types
                }
            }
          else
            { "ticket.subcategory_type" => { "operator" => "set_fixed_to", "set_fixed_to" => [ "" ] } }
          end

          CoreWorkflow.find_or_initialize_by(name: "ops - subcategory - #{subcat} - visible options").tap do |flow|
            flow.object = "Ticket"
            flow.preferences = { "screen" => [ "create_middle", "edit" ] }
            flow.condition_saved = {}
            flow.condition_selected = { "ticket.category" => { "operator" => "is", "value" => [ cat.to_s ] },
                                        "ticket.subcategory" => { "operator" => "is", "value" => [ subcat.to_s ] } }
            flow.perform = perform
            flow.priority = 700
            flow.updated_by_id = 1
            flow.created_by_id = 1
            flow.changeable = false
          end.save!
        end
      end
    end
  end
end

Rake::Task['db:migrate'].enhance do
  Rake::Task['ops:triage:migrate'].execute
end

Rake::Task['db:seed'].enhance do
  Rake::Task['ops:triage:migrate'].execute
end
