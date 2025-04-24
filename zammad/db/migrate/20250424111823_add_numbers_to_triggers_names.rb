class AddNumbersToTriggersNames < ActiveRecord::Migration[7.1]
  def up
    return unless Setting.exists?(name: 'system_init_done')

    Trigger.where(name: 'ops - preposielanie nových podnetov PRO zodpovedným subjektom').update_all(name: '2 - ops - preposielanie nových podnetov PRO zodpovedným subjektom')
    Trigger.where(name: 'ops - preposielanie upravených podnetov PRO zodpovedným subjektom').update_all(name: '2 - ops - preposielanie upravených podnetov PRO zodpovedným subjektom')
    Trigger.where(name: 'ops - preposielanie nových komentárov PRO zodpovedným subjektom').update_all(name: '2 - ops - preposielanie nových komentárov PRO zodpovedným subjektom')
    Trigger.where(name: 'ops - preposielanie - VZOR - <subjekt> - nový podnet').update_all(name: '2 - ops - preposielanie - VZOR - <subjekt> - nový podnet')
    Trigger.where(name: 'ops - preposielanie - VZOR - <subjekt> - komentáre z portálu').update_all(name: '2 - ops - preposielanie - VZOR - <subjekt> - komentáre z portálu')
    Trigger.where(name: 'ops - preposielanie - VZOR - <subjekt> - komentáre z triáže').update_all(name: '2 - ops - preposielanie - VZOR - <subjekt> - komentáre z triáže')
    Trigger.where(name: 'ops - nastavenie času poslednej zmeny zodpovedného subjektu').update_all(name: '9 - ops - nastavenie času poslednej zmeny zodpovedného subjektu')
    Trigger.where(name: 'ops - preposielanie upravených podnetov na portál').update_all(name: '2 - ops - preposielanie upravených podnetov na portál')
    Trigger.where(name: 'ops - preposielanie nových komentárov na portál').update_all(name: '2 - ops - preposielanie nových komentárov na portál')
    Trigger.where(name: 'ops - upozornenie na komentovanie uzavretých prijatých triážnych tiketov').update_all(name: '1 - ops - upozornenie na komentovanie uzavretých prijatých triážnych tiketov')
    Trigger.where(name: 'ops - upozornenie na komentovanie uzavretých zamietnutých triážnych tiketov').update_all(name: '1 - ops - upozornenie na komentovanie uzavretých zamietnutých triážnych tiketov')
    Trigger.where(name: 'ops - podnet označený za vyriešený - notifikácia').update_all(name: '8 - ops - podnet označený za vyriešený - notifikácia')
    Trigger.where(name: 'ops - zmena zodpovedného subjektu - notifikácia').update_all(name: '8 - ops - zmena zodpovedného subjektu - notifikácia')
    Trigger.where(name: 'ops - zmena zodpovedného subjektu agentom - notifikácia').update_all(name: '8 - ops - zmena zodpovedného subjektu agentom - notifikácia')
  end

  def down
    Trigger.where(name: '2 - ops - preposielanie - VZOR - <subjekt> - nový podnet').update_all(name: 'ops - preposielanie - VZOR - <subjekt> - nový podnet')
    Trigger.where(name: '2 - ops - preposielanie - VZOR - <subjekt> - komentáre z portálu').update_all(name: 'ops - preposielanie - VZOR - <subjekt> - komentáre z portálu')
    Trigger.where(name: '2 - ops - preposielanie - VZOR - <subjekt> - komentáre z triáže').update_all(name: 'ops - preposielanie - VZOR - <subjekt> - komentáre z triáže')
    Trigger.where(name: '9 - ops - nastavenie času poslednej zmeny zodpovedného subjektu').update_all(name: 'ops - nastavenie času poslednej zmeny zodpovedného subjektu')
    Trigger.where(name: '2 - ops - preposielanie upravených podnetov na portál').update_all(name: 'ops - preposielanie upravených podnetov na portál')
    Trigger.where(name: '2 - ops - preposielanie nových komentárov na portál').update_all(name: 'ops - preposielanie nových komentárov na portál')
    Trigger.where(name: '1 - ops - upozornenie na komentovanie uzavretých prijatých triážnych tiketov').update_all(name: 'ops - upozornenie na komentovanie uzavretých prijatých triážnych tiketov')
    Trigger.where(name: '1 - ops - upozornenie na komentovanie uzavretých zamietnutých triážnych tiketov').update_all(name: 'ops - upozornenie na komentovanie uzavretých zamietnutých triážnych tiketov')
    Trigger.where(name: '8 - ops - podnet označený za vyriešený - notifikácia').update_all(name: 'ops - podnet označený za vyriešený - notifikácia')
    Trigger.where(name: '8 - ops - zmena zodpovedného subjektu - notifikácia').update_all(name: 'ops - zmena zodpovedného subjektu - notifikácia')
    Trigger.where(name: '8 - ops - zmena zodpovedného subjektu agentom - notifikácia').update_all(name: 'ops - zmena zodpovedného subjektu agentom - notifikácia')
    Trigger.where(name: '2 - ops - preposielanie nových podnetov PRO zodpovedným subjektom').update_all(name: 'ops - preposielanie nových podnetov PRO zodpovedným subjektom')
    Trigger.where(name: '2 - ops - preposielanie upravených podnetov PRO zodpovedným subjektom').update_all(name: 'ops - preposielanie upravených podnetov PRO zodpovedným subjektom')
    Trigger.where(name: '2 - ops - preposielanie nových komentárov PRO zodpovedným subjektom').update_all(name: 'ops - preposielanie nových komentárov PRO zodpovedným subjektom')
  end
end
