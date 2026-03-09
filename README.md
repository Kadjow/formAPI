# FormAPI (Flutter)

Aplicativo Flutter que consome a API pública do JSONPlaceholder para listar posts e permite criar novos posts via formulário.  
Projeto desenvolvido com foco em boas práticas, arquitetura (MVVM), gerenciamento de estado, serialização, validação e testes.

---

## Funcionalidades

- **Listagem de posts** (título e descrição) via API
- **Criação de post** com formulário (título + descrição)
- **Validação de formulário**
  - Obrigatório
  - Limite de caracteres (Título **60**, Descrição **200**)
- **Paginação controlada** com botão “Carregar mais”
- **Detalhes do post** ao tocar em um item
- **Posts locais**
  - Posts criados são persistidos localmente
  - Remoção por swipe com **Desfazer (Undo)**
- **Tema Light/Dark** com transição suave e persistência
- **Splash screen** animada
- **Testes unitários e de widget**

---

## Arquitetura e organização

Arquitetura adotada: **MVVM** com **Riverpod**.

### Fluxo
**UI → ViewModel (state) → Repository (data) → (API / Cache Local)**

### Estrutura (resumo)
- `lib/features/posts/ui/` — telas (listagem, criação, detalhes)
- `lib/features/posts/state/` — ViewModel + providers (Riverpod)
- `lib/features/posts/data/` — repository + API service + local datasource
- `lib/core/` — utilitários globais (storage, snackbars, theme etc.)
- `test/` — testes unitários e de widget

---

## Como rodar o projeto

### Pré-requisitos
- Flutter instalado e configurado
- Emulador ou dispositivo conectado

### Rodar
```bash
flutter clean 
flutter pub get
flutter run