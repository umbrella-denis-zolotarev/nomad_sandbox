# Про проект
Продолжение разбора heshicorp продуктов.
Предыдущий проект https://github.com/umbrella-denis-zolotarev/consul_sandbox

В данном проекте добавляется дополнительный контейнер nomad и в нем запускается job
(руками, как именно описано ниже),
который запускает docker образ nginx и создает сервис consul.

# Немного про продукты
У consul, nomad и fabio есть возможность запустить agent. Agent
    - связывает их вместе через конфиги
    - открывает фронт дашбордов на портах
    - открывает апи для связи
- `Consul` для регистрации и обнаружения сервисов. Это точка связи. У Consul есть такие понятия как
  - `node` - физический сервер с запущенным Consul
  - `service`
    - подключенные агенты consul (в том числе собственный), nomad, fabio
    - сервисы consul (описвнные конфигурацией,  пример
      https://github.com/umbrella-denis-zolotarev/consul_sandbox/blob/main/.docker/consul_server/config/service.nginx_server.json )
    - сервисы поставляемые через job nomad [.docker/nomad/config/job.nginx.nomad](.docker/nomad/demo_jobs/job.nginx.nomad)
- `Nomad`
  - для регистрации job (изначально это файл конфигурации, который скармливантся вручную бинарнику nomad для запуска самой job на nomad,
    можно со стороннего сервера, например, gitlabci)
- `Fabio` - балансировщик, балансирует все сервисы consul, в которых есть таг "urlprefix-/" (тут / - любой путь) 

# Как запустить
1) `make up` запускаем агенты consul, fabio, nomad внутри docker-контейнеров с нужными сязями 
2) открываем сервисы в дашборде consul [http://localhost:8500/ui/dc1/services](http://localhost:8500/ui/dc1/services), дожидаемся когда все сервисы стартанут
- `consul` - агент consul в контейнере `consul_server`
- `nomad-1-client` - клиент агента nomad в контейнере `nomad_in_docker`
- `nomad-1-server` - сервер агента nomad в контейнере `nomad_in_docker`
- `fabio` - агент fabio в контейнере `fabio`
- позднее тут появится сервисы от job nomad, пока их нет
3) `make job-run` - говорим программе nomad доставить конфиг job в контейнер `nomad_in_docker`,
   где запускается task (docker образ nginx через host (на host машине крутящей `nomad_in_docker`)
   и создается сервис в consul)
4) Дальше можно посмотреть:
- [http://localhost:4646/ui/jobs](http://localhost:4646/ui/jobs) - джобы в дашборде номада
- [http://localhost:4646/ui/topology](http://localhost:4646/ui/topology) - метрики ноды номада в дашборде номада
- [http://localhost:8500/ui/dc1/services](http://localhost:8500/ui/dc1/services) - появился новый сервис `service-nginx` в дашборде консула
- [http://localhost:9998](http://localhost:9998) - появился новый сервис `service-nginx` в дашборде фабио
- [http://localhost:9999](http://localhost:9999) - в эндпоинте приложения fabio стала доступна страница nginx

5) Из консоли можно запустить команды для просмотра инфо о джобе (подробнее в [Makefile](Makefile))
- `make job-validate` - проверить конфиг джобы
- `make job-run` - запустить/перезапустить джобу
- `make job-status` - список запущенных джоб
- `make job-stop` - остановить джобу по имени
- `make job-allocs` - история запуска джобы (alloc - это инфо о запуске)
- `make job-last-alloc-id` - получение последнего ид запуска джобы
- `make job-last-alloc-status` - статус последнего запуска джобы

# Разбор конфигурации job

Официальная дока https://developer.hashicorp.com/nomad/docs/job-specification

Примеры
- [.docker/nomad/config/job.nginx.nomad](.docker/nomad/demo_jobs/job.nginx.nomad) - запускает образ nginx:alpine через docker
  (можно запустить в nomad через `make job-run`)
- [.docker/nomad/config/job.redis.nomad](.docker/nomad/demo_jobs/job.redis.nomad) - запускает образ redis:7 через docker
- [.docker/nomad/config/job.sleep.nomad](.docker/nomad/demo_jobs/job.sleep.nomad) - запускает `/bin/sleep 1000`

Описание
- `job`
  - значение - название, как будет видно job в админке nomad
  - дети
    - `region` - регион, где расположен кластер 
    - `datacenters` - датацентр, где расположен кластер
    - `type` - тип джоба, далее рассматривается для значения `service`
    - `group` - ряд задач, которые должны быть размещены в одном клиенте Nomad
      - значение - название группы 
      - дети
        - `network` - алиас порта сервиса (в примере http - это алиас),
          далее в описании service и task используется именно алиас порта
          - если пишем так `port "http" {}`, то будет случайный порт 
          - если пишем так `port "http" { static = 80 }`, то будет точный порт 
        - `service` - описание сервиса для consul
          - дети
            - `name` - имя сервиса в consul
            - `tags` - теги сервиса (`"urlprefix-/"` - для доступности в fabio)
            - `address` - адрес сервиса. По умолчанию адрес хоста, но может быть другой
              (в данном проекте nomad запускает task поднятия docker на хост машине
            (предварительно в nomad container проброшен сокет локального докера)), поэтому для `address` нужно указать
            значение `"host.docker.internal"`
            - `port` - значение - лейбл порта из `network`
            - `check` - healthcheck для consul
              - `type` - протокол проверки
              - `name` - имя проверки отображаемое в consul
              - `path` - относительный путь к эндпоинту проверки
              - `interval` - интервал проверки
              - `timeout` - таймаут проверки
        - `task` - задача для nomad
          - значение - название задачи
          - дети
            - `driver` - как запускать задачу, возможно значение `docker` (есть ещё другие, но их не рассмотриваем)
            - `config` - конфигурация драйвера, определяет что конкретно запускать
              - дети
                - `image` - образ докера (например, `"nginx:alpine"`)
                - `ports` - список алиасов портов (например, `["http"]`)
