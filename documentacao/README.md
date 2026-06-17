# Turbo Entregas — Documentação Central

> **Última atualização:** 07/05/2026  
> Toda alteração feita no projeto deve ser registrada aqui ou nos arquivos referenciados abaixo.

---

## Índice

| Arquivo | Descrição |
|---|---|
| [arquitetura/visao-geral.md](arquitetura/visao-geral.md) | Estrutura completa do projeto (apps + API) |
| [arquitetura/fluxo-pedido.md](arquitetura/fluxo-pedido.md) | Ciclo de vida de um pedido/parcela |
| [arquitetura/fluxo-pagamento.md](arquitetura/fluxo-pagamento.md) | Métodos de pagamento e fluxo financeiro |
| [features/saque-asaas.md](features/saque-asaas.md) | **[EM PROGRESSO]** Saque via ASAAS para entregadores |
| [features/entrega-adicional.md](features/entrega-adicional.md) | **[EM PROGRESSO]** Entrega adicional no pedido do cliente |
| [changelog/2026-05-07.md](changelog/2026-05-07.md) | Registro de alterações de hoje |

---

## Projetos

| Projeto | Tecnologia | Descrição |
|---|---|---|
| `Cliente/` | Flutter (Dart) | App do cliente final — pacote `sixam_mart` |
| `Entregador/` | Flutter (Dart) | App do entregador — pacote `sixam_mart_delivery` |
| `Painel_API/` | Laravel 10 (PHP 8.2) | Backend REST API + Painel Admin |

---

## Regras de Documentação

1. **Toda nova feature** deve ter seu arquivo em `features/`.
2. **Todo bug corrigido ou comportamento alterado** deve ser registrado em `changelog/YYYY-MM-DD.md`.
3. **Caminhos de arquivos** devem ser relativos à raiz do projeto correspondente.
4. **Decisões de arquitetura** relevantes vão em `arquitetura/`.
