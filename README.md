# 📌 FormAPI

Aplicativo em **Flutter** para listar posts a partir de uma API pública e permitir a criação de novos posts via formulário, com uma experiência mais próxima de um app real, incluindo **paginação, cache local, tema e testes**.

A ideia do projeto é ser um app simples, mas bem estruturado, para praticar e demonstrar:

- consumo de API (`GET` / `POST`);
- validação de formulário;
- serialização de dados;
- arquitetura com separação de camadas;
- testes unitários e de widget;
- e polimentos de UX.

---

## 🎯 Objetivo do projeto

O **FormAPI** foi pensado para:

- praticar desenvolvimento mobile com Flutter;
- trabalhar consumo de API externa e serialização de dados;
- implementar formulário com validações e envio;
- organizar o projeto com uma arquitetura clara (**MVVM + Riverpod**);
- servir como base para evoluções futuras, como busca, filtros e melhorias de UI/UX.

---

## ✨ Funcionalidades

### ✅ Atuais

- 📥 **Listar posts** consumindo a API pública  
  - `GET: https://jsonplaceholder.typicode.com/posts`

- 📝 **Criar post** via formulário  
  - Campos: **Título** + **Descrição**
  - `POST: https://jsonplaceholder.typicode.com/posts`

- ✅ **Validação de formulário**
  - campos obrigatórios;
  - não permite salvar vazio;
  - limite de caracteres:
    - **Título:** 60
    - **Descrição:** 200
  - botão **Salvar post** desabilitado enquanto o formulário estiver inválido.

- ➕ **Paginação controlada**
  - botão **Carregar mais** adiciona novos itens gradualmente;
  - em caso de falha, exibe feedback amigável com `SnackBar`, sem quebrar a listagem.

- 🧭 **Tela de detalhes**
  - ao tocar em um post, abre uma página com as informações detalhadas.

- 💾 **Armazenamento local (cache)**
  - posts criados ficam persistidos localmente com `SharedPreferences`;
  - aba **Locais** separa os posts criados pelo usuário.

- 🧹 **Remoção com Undo**
  - swipe para excluir post local;
  - `SnackBar` com ação **DESFAZER** para restaurar o item.

- 🌗 **Tema Light/Dark**
  - alternância por toggle;
  - persistência da escolha do usuário;
  - transição suave entre temas.

- 🚀 **Splash screen** animada

- 🧪 **Testes**
  - testes **unitários** e **de widget**;
  - execução com `flutter test`.

---

## 🧰 Tecnologias utilizadas

- **Flutter**
- **Dart**
- **Riverpod** — gerenciamento de estado
- **Dio** — cliente HTTP
- **json_serializable / json_annotation** — serialização
- **SharedPreferences** — persistência local
- **flutter_test** — testes

### Plataformas suportadas

O projeto possui suporte gerado pelo Flutter para:

- Android
- iOS
- Web
- Linux
- macOS
- Windows

---

## 🧱 Arquitetura

Arquitetura adotada: **MVVM + Riverpod**, com separação por feature.

### Fluxo da aplicação

```text
UI → ViewModel (state) → Repository (data) → API / Cache Local
```

### Estrutura resumida

- `lib/features/posts/ui/` → telas (listagem, criação e detalhes)
- `lib/features/posts/state/` → ViewModel e providers
- `lib/features/posts/data/` → repository, API service e datasource local
- `lib/core/` → utilitários globais (tema, storage, snackbars, etc.)
- `test/` → testes unitários e de widget

---

## 📁 Estrutura do projeto

```text
formAPI/
├── android/                # Projeto nativo Android gerado pelo Flutter
├── ios/                    # Projeto nativo iOS gerado pelo Flutter
├── web/                    # Entrypoint e assets para navegador
├── linux/                  # Suporte a desktop Linux
├── macos/                  # Suporte a desktop macOS
├── windows/                # Suporte a desktop Windows
├── lib/
│   ├── core/               # Utilitários globais (tema, snackbars, storage, etc.)
│   └── features/
│       ├── splash/         # Splash screen
│       └── posts/          # Feature principal (data/state/ui)
├── test/                   # Testes unitários e de widget
├── pubspec.yaml            # Dependências e configurações gerais
├── pubspec.lock
├── analysis_options.yaml   # Regras de análise estática (lint)
├── .gitignore
└── README.md
```

---

## 🛠 Pré-requisitos

Antes de rodar o projeto, você precisa ter instalado:

- **Flutter SDK**
- um **emulador**, **simulador** ou **dispositivo físico**
- ambiente configurado para a plataforma desejada (Android, iOS, Web ou Desktop)

Verifique se o ambiente está pronto com:

```bash
flutter doctor
```

---

## 🚀 Como rodar o projeto

No diretório do projeto, execute:

```bash
flutter pub get
flutter run
```

### Executando em plataformas específicas

```bash
# Android
flutter run -d android

# Web (Chrome)
flutter run -d chrome

# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

---

## 🧪 Testes

Para rodar todos os testes:

```bash
flutter test
```

Para análise estática:

```bash
flutter analyze
```

---

## 📌 Notas importantes sobre a API

A API utilizada no projeto é o **JSONPlaceholder**:

- `GET: https://jsonplaceholder.typicode.com/posts`
- `POST: https://jsonplaceholder.typicode.com/posts`

> O JSONPlaceholder **não persiste** os dados enviados via `POST` de forma real.  
> Ele apenas simula a resposta da criação.

Por isso, para manter uma experiência mais realista, os posts criados no app são armazenados localmente com **SharedPreferences**.

---

## 📌 Possíveis próximos passos

Ideias para evoluir o **FormAPI**:

- 🔎 busca por título e descrição;
- 🧩 filtros e ordenação;
- 📶 melhorias na experiência offline;
- 🎨 refinamentos de UI/UX, como skeleton loaders, acessibilidade e animações;
- 📦 persistência mais robusta com **SQLite**, **Drift** ou **Hive**;
- 🧪 expansão da cobertura de testes, incluindo mocks de API, testes de repository e golden tests.

---

## 👨‍💻 Autor

**Diogo Arthur Gulhak**  
Desenvolvedor de Software focado em **Flutter**, **Dart**, desenvolvimento mobile e boas práticas de arquitetura.

- **GitHub:** [@Kadjow](https://github.com/Kadjow)
- **LinkedIn:** Diogo Arthur Gulhak
