<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Parceiro Let's Food</title>
  <link rel="icon" href="{{ url('/icofavicon.png') }}" type="image/png">
  <link rel="shortcut icon" href="{{ url('/icofavicon.png') }}" type="image/png">
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
      font-family: Arial, sans-serif;
    }
    body {
      background: #fff;
      color: #333;
    }
    header {
      width: 100%;
      background: #fff;
      box-shadow: 0 2px 10px rgba(0,0,0,0.1);
      position: fixed;
      top: 0;
      left: 0;
      z-index: 1000;
      padding: 10px 0;
    }
    .container {
      max-width: 1200px;
      margin: 0 auto;
      padding: 15px 20px;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    header .logo {
      display: flex;
      align-items: center;
      text-decoration: none;
    }
    header .logo img {
      height: 50px;
      margin-right: 10px;
    }
    header nav {
      display: flex;
      align-items: center;
      gap: 30px;
    }
    .nav-link {
      color: #333;
      text-decoration: none;
      font-size: 15px;
      font-weight: 600;
      transition: all 0.3s;
      padding: 5px 0;
      position: relative;
    }
    .nav-link:after {
      content: '';
      position: absolute;
      width: 0;
      height: 2px;
      bottom: 0;
      left: 0;
      background-color: #83e406;
      transition: width 0.3s;
    }
    .nav-link:hover:after {
      width: 100%;
    }
    .nav-link:hover {
      color: #83e406;
    }
    .btn-cadastrar {
      background: #83e406;
      color: #fff !important;
      padding: 10px 25px;
      border-radius: 25px;
      font-weight: 700;
      text-decoration: none;
      transition: all 0.3s;
      font-size: 15px;
      box-shadow: 0 4px 15px rgba(131, 228, 6, 0.3);
    }
    .btn-cadastrar:hover {
      background: #6bc200;
      transform: translateY(-2px);
      box-shadow: 0 6px 20px rgba(131, 228, 6, 0.4);
    }
    
    /* Wave Divider */
    .wave-divider {
      position: relative;
      width: 100%;
      height: 20px;
      overflow: hidden;
      margin-top: -1px;
    }
    
    .wave-divider svg {
      position: relative;
      display: block;
      width: 100%;
      height: 100%;
    }
    
    .wave-divider .shape-fill {
      fill: #6bc200;
      opacity: 0.1;
    }
    .menu-toggle {
      display: none;
      flex-direction: column;
      justify-content: space-between;
      width: 24px;
      height: 18px;
      cursor: pointer;
    }
    .menu-toggle span {
      display: block;
      width: 100%;
      height: 2px;
      background: #333;
      transition: all 0.3s;
    }
    @media (max-width: 768px) {
      .hero {
        min-height: 50vh;
        padding-top: 80px;
        background-size: cover;
        background-position: center center;
      }
      .menu-toggle {
        display: flex;
      }
      header nav {
        display: none;
        position: absolute;
        top: 100%;
        left: 0;
        right: 0;
        background: #fff;
        flex-direction: column;
        padding: 20px;
        box-shadow: 0 4px 6px rgba(0,0,0,0.1);
      }
      header nav.active {
        display: flex;
      }
      .nav-link, .btn-cadastrar {
        padding: 10px 0;
        width: 100%;
        text-align: center;
      }
    }
    .hero {
      position: relative;
      width: 100%;
      min-height: 100vh;
      background: url("{{ asset('capa.png') }}") center/cover no-repeat;
      background-size: cover;
      background-position: center center;
      display: flex;
      justify-content: center;
      align-items: flex-start;
      padding-top: 100px;
      overflow: hidden;
      background-color: #f8f8f8;
    }
    .hero .form-box {
      background: #fff;
      padding: 20px;
      border-radius: 8px;
      box-shadow: 0 4px 10px rgba(0,0,0,0.1);
      width: 300px;
    }
    .form-box h3 {
      margin-bottom: 15px;
      font-size: 18px;
    }
    .form-box input {
      width: 100%;
      padding: 10px;
      margin-bottom: 15px;
      border: 1px solid #ccc;
      border-radius: 5px;
    }
    .form-box button {
      width: 100%;
      padding: 10px;
      background: #83e406;
      border: none;
      color: #fff;
      font-weight: bold;
      border-radius: 5px;
      cursor: pointer;
    }
    section.vantagens {
      background: #fff;
      padding: 30px 20px 20px;
      text-align: center;
    }
    section.vantagens h2 {
      margin-bottom: 15px;
      font-size: 22px;
    }
    .vantagens-container {
      display: flex;
      flex-wrap: wrap;
      justify-content: center;
      max-width: 1000px;
      margin: 0 auto;
      padding: 5px 0 0;
    }
    .vantagem {
      margin: 5px 10px 15px;
      text-align: center;
      width: 200px;
    }
    .vantagem img {
      width: 35px;
      margin-bottom: 8px;
    }
    section.comparativo {
      padding: 60px 20px;
      background: #0d8239;
      text-align: center;
      color: #fff;
    }
    .comparativo h2 {
      font-size: 26px;
      margin-bottom: 30px;
    }
    .comparativo-container {
      display: flex;
      justify-content: center;
      flex-wrap: wrap;
      gap: 30px;
    }
    .plano {
      background: #fff;
      color: #333;
      border-radius: 12px;
      padding: 30px 25px;
      width: 350px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
      text-align: left;
      transition: transform 0.3s ease;
      margin-bottom: 20px;
    }
    .plano h3 {
      font-size: 24px;
      margin-bottom: 20px;
      color: #d32f2f;
      text-align: center;
      font-weight: 700;
    }
    .plano.green h3 {
      color: #44a035;
    }
    .plano p {
      font-size: 16px;
      margin: 15px 0;
      text-align: left;
      line-height: 1.5;
    }
    .plano p small {
      font-size: 14px;
      color: #777;
    }
    .plano p strong {
      font-size: 28px;
      color: #333;
    }
    .plano ul {
      margin-top: 15px;
      padding-left: 20px;
      list-style: none;
    }
    .plano ul li {
      margin-bottom: 8px;
      position: relative;
      padding-left: 22px;
      color: #555;
      line-height: 1.4;
      font-size: 14px;
      padding-right: 5px;
    }
    .plano ul li:before {
      content: "•";
      color: #44a035;
      font-size: 24px;
      font-weight: bold;
      position: absolute;
      left: -20px;
      line-height: 1;
    }
    .plano:not(.green) ul li:before {
      color: #d32f2f;
    }
    .footer-text {
      margin-top: 40px;
      font-size: 20px;
      font-weight: bold;
      color: #fff;
    }
    footer {
      background: #83e406;
      text-align: center;
      color: #fff;
      padding: 15px;
      font-size: 14px;
    }
  </style>
</head>
<body>

  <header>
    <div class="container">
      <a href="#" class="logo">
        <img src="{{ url('/logo.png') }}" alt="Let's Food" style="height: 45px;">
      </a>
      <nav>
        <a href="{{ route('entregador') }}" class="nav-link">Entregador Let's Food</a>
        <a href="#como-funciona" class="nav-link">Como Funciona</a>
        <a href="#planos" class="nav-link">Planos</a>
        <a href="#contato" class="nav-link">Painel parceiro</a>
        <a href="#" class="btn-cadastrar">Quero ser Parceiro</a>
      </nav>
      <div class="menu-toggle">
        <span></span>
        <span></span>
        <span></span>
      </div>
    </div>
  </header>

  <section class="hero">
  </section>

  <div class="wave-divider">
    <svg viewBox="0 0 1200 20" preserveAspectRatio="none">
      <path d="M0,20 C200,10 400,15 600,10 C800,5 1000,10 1200,5 L1200,20 L0,20 Z" class="shape-fill"></path>
    </svg>
  </div>

  <section class="vantagens">
    <h2>Vantagens de ser uma loja parceira</h2>
    <div class="vantagens-container">
      <div class="vantagem">
        <img src="https://cdn-icons-png.flaticon.com/512/1046/1046784.png" alt="">
        <p><strong>Entrega fácil</strong><br>Entregamos todos os seus pedidos via parceiros Let's Food.</p>
      </div>
      <div class="vantagem">
        <img src="https://cdn-icons-png.flaticon.com/512/992/992651.png" alt="">
        <p><strong>Taxa que respeita você</strong><br>Pague até 17% menos em taxas comparado ao mercado.</p>
      </div>
      <div class="vantagem">
        <img src="https://cdn-icons-png.flaticon.com/512/847/847969.png" alt="">
        <p><strong>Gestão simples</strong><br>Controle seus pedidos de forma rápida e prática.</p>
      </div>
      <div class="vantagem">
        <img src="https://cdn-icons-png.flaticon.com/512/633/633652.png" alt="">
        <p><strong>Repasse semanal</strong><br>Receba seus repasses sem burocracia.</p>
      </div>
    </div>
  </section>

  <section class="comparativo">
    <h2>CHEGA DE TRABALHAR PARA PAGAR TAXAS</h2>
    <div class="comparativo-container">
      <div class="plano">
        <h3>iFood</h3>
        <p><strong>6%</strong> Comissão sobre pedidos</p>
        <p><strong>3,2%</strong> Taxa para pedidos pagos via Let's Food</p>
        <p>R$ 150,00 a R$ 180,00 / mês<br><small>Mensalidade</small></p>
        <hr style="margin:15px 0; border: 0; border-top: 1px solid #eee;">
        <ul>
          <li>Taxas para Antecipação</li>
          <li>Taxas Ocultas</li>
        </ul>
      </div>
      <div class="plano green">
        <h3>LET'S FOOD</h3>
        <p><strong>3,2%</strong> Comissão sobre pedidos</p>
        <p><strong>3,2%</strong> Taxa para pedidos pagos via Let's Food</p>
        <p>R$ 0,00/mês <span style="color:#44a035;font-weight:bold;">GRÁTIS</span><br><small>Mensalidade</small></p>
        <hr style="margin:15px 0; border: 0; border-top: 1px solid #eee;">
        <ul>
          <li>Sua loja no app do Let's Food</li>
          <li>Entrega com parceiros Let's Food</li>
          <li>Rastreio de entrega em tempo real</li>
          <li>Gestor de pedidos</li>
          <li>Atendimento humanizado</li>
        </ul>
      </div>
    </div>
    <p class="footer-text">Pague até 17% menos em taxas</p>
  </section>

  <footer>
    © 2025 Let's Food - Todos os direitos reservados
  </footer>

  <script>
    // Menu mobile toggle
    document.addEventListener('DOMContentLoaded', function() {
      const menuToggle = document.querySelector('.menu-toggle');
      const nav = document.querySelector('header nav');
      
      menuToggle.addEventListener('click', function() {
        nav.classList.toggle('active');
      });
      
      // Fechar menu ao clicar em um link
      const navLinks = document.querySelectorAll('header nav a');
      navLinks.forEach(link => {
        link.addEventListener('click', () => {
          nav.classList.remove('active');
        });
      });
    });
  </script>
</body>
</html>
