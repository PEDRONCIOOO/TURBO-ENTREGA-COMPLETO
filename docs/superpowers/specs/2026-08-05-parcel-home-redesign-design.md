# Redesign da ParcelCategoryScreen (Home de Entregas)

**Data:** 2026-08-05
**Branch:** Tela/Entregas
**Escopo:** Redesign visual da tela principal do modulo parcel no app Cliente Flutter

## Contexto

A ParcelCategoryScreen e a home principal quando o modulo parcel esta ativo. Atualmente tem um visual stock com banner generico, textos em ingles, e um GIF de drone como placeholder. O redesign aplica o design system "big tech" ja iniciado em sessoes anteriores (nav bar flutuante, cards com sombras, cores laranja #F4870C).

## Decisoes de Design

1. **Banner**: Manter carousel API-driven, aplicar visual premium
2. **Titulos**: Trocar ingles por PT-BR contextual
3. **Cards**: Gradiente sutil no icone, sombras refinadas
4. **Secao info**: Usar dados `whyChooseDetails` da API (substituir drone GIF)
5. **Background**: Scaffold #FAFAFA para contraste com cards brancos

## Mudancas Detalhadas

### 1. Scaffold Background

- Cor de fundo do Scaffold: `Color(0xFFFAFAFA)`
- Cria contraste com cards brancos e da profundidade visual

### 2. Banner Carousel (visual premium)

**Arquivo:** `parcel_category_screen.dart`

Manter `CarouselSlider` com dados de `parcelOtherBannerModel`. Mudancas visuais:

- `borderRadius: 16` (era `radiusDefault`)
- Height mobile: `140` (era `120`)
- Adicionar gradient overlay na imagem: `LinearGradient` de `Colors.transparent` (topo) para `Colors.black.withOpacity(0.4)` (base) — melhora legibilidade de eventual texto
- Adicionar page indicators abaixo do carousel:
  - `AnimatedContainer` com duracao 300ms
  - Dot ativo: largura 20px, altura 6px, borderRadius 3, cor primaryColor
  - Dot inativo: 6x6, borderRadius 3, cor primaryColor com 30% opacity
  - Row centralizada, spacing 4px
  - Margem top 10px
- Fallback quando `banners` esta vazio ou null (apos loading):
  - Container com gradiente laranja (`LinearGradient` de `#F4870C` para `#FF6B35`)
  - borderRadius 16, height 140
  - Texto: "Envie qualquer coisa, agora" (robotoBold, branco, fontSize 18)
  - Subtexto: "Entrega rapida e segura na sua cidade" (robotoRegular, branco 85%)
  - Circulos decorativos com branco 12% e 8% opacity (posicao absoluta)

### 3. Titulo de Secao (PT-BR)

**Arquivo:** `parcel_category_screen.dart` + `messages.php`

Substituir:
- `'bringing_happiness_from_door_to_door'.tr` -> `'what_do_you_need_to_send'.tr`
  - Traducao PT: "O que voce precisa enviar?"
  - Estilo: `robotoBold.copyWith(fontSize: 18, fontWeight: FontWeight.w800)`
- `'ready_to_send_something_special'.tr` -> `'choose_your_delivery_category'.tr`
  - Traducao PT: "Escolha a categoria da sua entrega"
  - Estilo: `robotoRegular.copyWith(fontSize: 13, color: Theme.of(context).disabledColor)`

### 4. Cards de Categoria (gradiente no icone)

**Arquivo:** `deliver_item_card_widget.dart`

Mudancas no container do icone:
- Background: `LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [primaryColor.withOpacity(0.12), primaryColor.withOpacity(0.06)])`
  - Era: cor solida `primaryColor.withOpacity(0.08)`
- Decoration do card: `BoxDecoration` com gradient ao inves de cor solida

Mudancas na sombra do card:
- `BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: Offset(0, 2))`
  - Manter como esta (ja foi ajustado em sessao anterior)

Mudanca na borda do card:
- `primaryColor.withOpacity(0.06)` (era 0.08 quando selecionado e grey.200 quando nao)
  - Unificar para 0.06 em ambos estados, selecionado adiciona primaryColor.withOpacity(0.15)

### 5. Secao "Por que escolher" (substitui drone GIF)

**Novo arquivo:** `Cliente/lib/features/parcel/widgets/why_choose_section_widget.dart`
**Remover:** `user_location_map_widget.dart` (era apenas `Image.asset('assets/image/drone1.gif')`)
**Atualizar import em:** `parcel_category_screen.dart` — trocar `UserLocationMapWidget` por `WhyChooseSectionWidget`

Novo widget `WhyChooseSectionWidget`:
- Recebe dados de `parcelController.whyChooseDetails`
- Container: branco, borderRadius 16, sombra `black 3% opacity, blur 8`
- Padding: 16px
- Titulo: "Por que escolher a Turbo?" — robotoBold, fontSize 14
  - Ou usar titulo do primeiro banner se disponivel
- Lista dos banners de `whyChooseDetails`:
  - Cada item: Row com icone circular (32px, fundo primaryColor 10%, icone check laranja) + Column(titulo bold + descricao disabledColor)
  - Spacing vertical: 12px entre itens
  - Se `imageFullUrl` disponivel: usar imagem ao inves de icone generico
- Fallback se API vazia: widget retorna `SizedBox.shrink()` (nao renderiza)
- Margem: top 16px

### 6. Arquivo de traducoes

**Arquivo:** `Painel_API/resources/lang/pt/messages.php`

Novas chaves:
```php
'what_do_you_need_to_send' => 'O que voce precisa enviar?',
'choose_your_delivery_category' => 'Escolha a categoria da sua entrega',
'why_choose_us' => 'Por que escolher a Turbo?',
```

## Arquivos Alterados

| Arquivo | Tipo | Descricao |
|---------|------|-----------|
| `Cliente/lib/features/parcel/screens/parcel_category_screen.dart` | Edit | Scaffold bg, banner styling, indicators, titulos, secao whyChoose |
| `Cliente/lib/features/parcel/widgets/deliver_item_card_widget.dart` | Edit | Gradiente no icon container |
| `Cliente/lib/features/parcel/widgets/why_choose_section_widget.dart` | New | Widget WhyChooseSectionWidget com dados da API |
| `Cliente/lib/features/parcel/widgets/user_location_map_widget.dart` | Delete | Remover (era apenas drone GIF) |
| `Painel_API/resources/lang/pt/messages.php` | Edit | Novas chaves i18n |

## Fora de Escopo

- Redesign de telas food/grocery/ecommerce
- Mudancas na ParcelAppBarWidget (ja redesenhada)
- Mudancas na bottom nav bar (ja redesenhada)
- Mudancas no flow parcel (location, request screens)
- Dark mode (manter comportamento existente)
