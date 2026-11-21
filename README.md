# Reservas Hídricas — Monitoramento de Estufas

Projeto acadêmico desenvolvido em **Dart** para acompanhar dados de estações de monitoramento de estufas, com armazenamento em **MySQL** e interface de menu no terminal.

O sistema permite consultar leituras de telemetria, médias de temperatura, umidade do solo e nível da água, despesas, acionamentos de bombas e anotações de campo. Também apresenta recomendações de irrigação baseadas nos dados registrados. Os dados utilizados nas demonstrações e testes são simulados; o sistema não controla fisicamente a irrigação nem envia alertas automaticamente.

## Tecnologias

- Dart (SDK compatível com `^3.0.0`)
- MySQL
- Pacote Dart `mysql_client: ^0.0.27`
- Terminal e, opcionalmente, Visual Studio Code

## Funcionalidades

No menu principal estão disponíveis:

1. Selecionar estação de monitoramento.
2. Consultar leituras de telemetria, inclusive leituras com alerta.
3. Consultar médias da estação.
4. Consultar gastos, custos e totais por categoria.
5. Consultar acionamentos e tempo de funcionamento da bomba.
6. Consultar anotações de campo.
7. Visualizar recomendação de irrigação baseada nos dados da estação.
8. Cadastrar leitura, gasto ou anotação de campo.
9. Simular uma leitura automática.
10. Verificar se uma estação pode ser removida, considerando dados vinculados.
11. Consultar estatísticas do banco de dados.
0. Encerrar o programa.

## Organização dos arquivos

```text
reservas_hidricas/
├── bin/
│   ├── main.dart                  # Menu interativo conectado ao MySQL
│   ├── demonstracao.dart          # Demonstração das regras sem banco
│   └── testes_serializacao.dart   # Testes de modelos e orientação a objetos
├── lib/
│   ├── dados/
│   │   └── demonstracao.dart      # Casos demonstrativos e validações
│   ├── excecoes/
│   │   └── regra_de_negocio_exception.dart
│   ├── interfaces/
│   │   └── serializavel.dart
│   ├── menu/
│   │   └── menu_interativo.dart
│   ├── models/
│   │   ├── acionamento_bomba.dart
│   │   ├── anotacao_campo.dart
│   │   ├── dispositivo_broker.dart
│   │   ├── estacao_monitoramento.dart
│   │   ├── leitura_telemetria.dart
│   │   ├── registro_com_data.dart
│   │   ├── registro_gasto.dart
│   │   └── usuario.dart
│   ├── src/
│   │   ├── banco.dart             # Configuração e conexão MySQL
│   │   └── repositorio.dart       # Consultas e operações no banco
│   └── utils/
│       └── validacao.dart
├── pubspec.yaml
└── README.md
```

## Requisitos de orientação a objetos

### 1. Herança — `extends`

`RegistroComData` é uma classe abstrata que declara `DateTime get data`. Quatro classes a estendem e implementam esse getter com `@override`:

- `LeituraTelemetria`
- `RegistroGasto`
- `AcionamentoBomba`
- `AnotacaoCampo`

### 2. Interface — `implements`

A interface `Serializavel` define os métodos `toMap()` e `toJson()`. Ela é implementada pelos sete modelos concretos: `Usuario`, `DispositivoBroker`, `EstacaoMonitoramento`, `LeituraTelemetria`, `RegistroGasto`, `AcionamentoBomba` e `AnotacaoCampo`.

A exceção personalizada `RegraDeNegocioException` também utiliza `implements Exception`.

### 3. Coleções de objetos

`EstacaoMonitoramento` mantém coleções tipadas de objetos relacionados, como leituras, gastos, acionamentos de bomba, anotações e dispositivos brokers. Essas coleções são incluídas na serialização da estação.

### 4. Conversão de objetos — `toMap()` e `toJson()`

Os modelos podem ser representados como mapas (`Map<String, dynamic>`) e como texto JSON. A implementação contempla datas em formato ISO 8601, campos opcionais/nulos e objetos aninhados. Os dados de senha do usuário não são expostos na serialização.

### 5. Polimorfismo

O teste utiliza uma `List<RegistroComData>` contendo objetos de quatro subclasses diferentes e acessa `registro.data` por meio da mesma interface da classe base.

## Como executar

### 1. Instalar as dependências

Com o Dart instalado, abra um terminal na raiz do projeto e execute:

```bash
dart pub get
```

### 2. Executar os testes sem MySQL

```bash
dart analyze
dart run bin/testes_serializacao.dart
dart run bin/demonstracao.dart
```

- `dart analyze`: verifica problemas detectados pela análise estática.
- `testes_serializacao.dart`: executa 14 verificações de serialização, herança e polimorfismo. O programa retorna código de saída diferente de zero se algum teste falhar.
- `demonstracao.dart`: apresenta exemplos de regras de negócio, validações e cálculos, **sem exigir conexão com o banco**.

### 3. Preparar o MySQL

Para utilizar o menu principal, é necessário ter um servidor MySQL funcionando e um banco com as tabelas esperadas pelo repositório.

**Atenção:** o ZIP revisado não inclui um script `.sql` de criação e povoamento do banco. Portanto, executar apenas `dart pub get` **não cria as tabelas nem adiciona dados**. Utilize o banco já preparado para o projeto ou obtenha o script correspondente antes de iniciar o menu.

A classe `ConexaoBanco` lê as seguintes variáveis de ambiente:

| Variável | Finalidade | Valor padrão no código |
|---|---|---|
| `DB_HOST` | Endereço do servidor | `127.0.0.1` |
| `DB_PORT` | Porta MySQL | `3306` |
| `DB_USER` | Usuário do banco | `root` |
| `DB_PASS` | Senha do banco | Há uma senha fixa no código atual; recomenda-se removê-la |
| `DB_NAME` | Nome do banco | `reservas_hidricas` |
| `DB_SECURE` | Habilitar conexão segura | `false` |

Exemplo de configuração no **PowerShell** (substitua os valores conforme seu ambiente):

```powershell
$env:DB_HOST = "127.0.0.1"
$env:DB_PORT = "3306"
$env:DB_USER = "seu_usuario"
$env:DB_PASS = "sua_senha"
$env:DB_NAME = "reservas_hidricas"
```

Esses comandos definem as variáveis apenas no processo/sessão atual do PowerShell.

> **Aviso de segurança:** a versão examinada de `lib/src/banco.dart` contém uma senha embutida como valor alternativo para `DB_PASS`. Antes de publicar o código ou compartilhar o projeto, remova essa senha fixa, use credenciais próprias por ambiente e altere a senha no MySQL caso ela seja real. Não inclua credenciais em arquivos versionados.

### 4. Iniciar o menu conectado ao banco

```bash
dart run bin/main.dart
```

Após conectar, o programa apresenta o menu para selecionar uma estação e utilizar suas funcionalidades. Se a conexão falhar, verifique o serviço MySQL, o banco, as tabelas e as credenciais.

## Testes e validações

O projeto contém dois executáveis independentes do banco:

- `bin/testes_serializacao.dart`: 14 testes para os modelos, a interface, herança e polimorfismo.
- `bin/demonstracao.dart`: demonstração das regras de negócio e de sete situações de validação, incluindo limites de nível, valores de gasto, e-mail, IP, intervalo de acionamento e senha.

Segundo o relatório de validação fornecido para esta versão, os resultados obtidos foram **14/14 testes aprovados**, **7/7 validações aprovadas** e `dart analyze` sem problemas. Esses resultados devem ser reproduzidos no ambiente de entrega. O menu também foi testado anteriormente em um banco MySQL configurado, realizando consultas reais.

## Limitações

- O menu conectado ao MySQL depende de um esquema de banco já existente.
- O pacote revisado não contém os arquivos SQL ou CSV de dados mencionados em outras etapas do projeto.
- As recomendações de irrigação são informativas: não acionam bombas físicas.
- As verificações de regras e alertas são feitas com base nos dados; não há envio automático de notificações.
- A implementação atual é destinada ao contexto acadêmico e precisa de revisão de segurança antes de uso em produção, especialmente quanto ao tratamento das credenciais e das senhas.

## Contexto acadêmico

Este projeto foi desenvolvido para aplicar conceitos de orientação a objetos em Dart, integrados a um sistema de monitoramento de reservas hídricas e estufas com dados simulados. Sua execução e os testes permitem demonstrar herança, interfaces, coleções, serialização e polimorfismo, sem modificar o fluxo original do menu.
