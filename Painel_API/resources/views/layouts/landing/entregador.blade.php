<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Seja um Entregador Parceiro - Let's Food</title>
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

  <section class="hero" style="background: linear-gradient(rgba(0, 0, 0, 0.6), rgba(0, 0, 0, 0.6)), url('https://images.unsplash.com/photo-1600891964098-4316c2880322?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1740&q=80') center/cover no-repeat;">
    <div class="container">
      <div class="hero-content" style="max-width: 800px; text-align: center; color: #fff; margin: 0 auto; padding: 100px 20px;">
        <h1 style="font-size: 2.8rem; margin-bottom: 20px; line-height: 1.2;">
          Seja um entregador parceiro
        </h1>
        <p style="font-size: 1.4rem; margin-bottom: 40px; max-width: 700px; margin-left: auto; margin-right: auto;">
          Ganhe dinheiro fazendo entregas quando e onde quiser. Tenha flexibilidade de horários e receba seus ganhos toda semana.
        </p>
        <div style="display: flex; gap: 15px; flex-wrap: wrap; justify-content: center; margin-bottom: 50px;">
          <a href="#cadastro" class="btn-cadastrar" style="padding: 15px 30px; font-size: 1.1rem; font-weight: 600;">
            Quero ser Entregador
          </a>
          <a href="#ganhos" class="btn-cadastrar" style="padding: 15px 30px; font-size: 1.1rem; font-weight: 600; background: transparent; border: 2px solid #fff;">
            Saiba mais
          </a>
        </div>
        <div style="display: flex; gap: 30px; flex-wrap: wrap; justify-content: center; background: rgba(0,0,0,0.4); padding: 20px; border-radius: 10px; max-width: 800px; margin: 0 auto;">
          <div style="text-align: center; flex: 1; min-width: 120px;">
            <div style="font-size: 2rem; font-weight: bold; color: #fff;">R$ 7-12</div>
            <div style="font-size: 0.9rem;">por entrega + gorjetas</div>
          </div>
          <div style="height: 50px; width: 1px; background: rgba(255,255,255,0.3);"></div>
          <div style="text-align: center; flex: 1; min-width: 120px;">
            <div style="font-size: 2rem; font-weight: bold; color: #fff;">100%</div>
            <div style="font-size: 0.9rem;">flexível</div>
          </div>
          <div style="height: 50px; width: 1px; background: rgba(255,255,255,0.3);"></div>
          <div style="text-align: center; flex: 1; min-width: 120px;">
            <div style="font-size: 2rem; font-weight: bold; color: #fff;">7 dias</div>
            <div style="font-size: 0.9rem;">para o primeiro pagamento</div>
          </div>
        </div>
      </div>
    </div>
  </section>

  <div class="wave-divider">
    <svg viewBox="0 0 1200 20" preserveAspectRatio="none">
      <path d="M0,20 C200,10 400,15 600,10 C800,5 1000,10 1200,5 L1200,20 L0,20 Z" class="shape-fill"></path>
    </svg>
  </div>

  <section class="vantagens">
    <h2>Vantagens de ser um entregador Let's Food</h2>
    <div class="vantagens-container">
      <div class="vantagem">
        <img src="https://cdn-icons-png.flaticon.com/512/2438/2438078.png" alt="Horário flexível">
        <p><strong>Horário flexível</strong><br>Escolha seus horários de trabalho e atenda quando quiser.</p>
      </div>
      <div class="vantagem">
        <img src="https://cdn-icons-png.flaticon.com/512/3132/3132693.png" alt="Ganhos atrativos">
        <p><strong>Ganhos atrativos</strong><br>Receba por entrega + gorjetas dos clientes.</p>
      </div>
      <div class="vantagem">
        <img src="https://cdn-icons-png.flaticon.com/512/3050/3050525.png" alt="Pagamento semanal">
        <p><strong>Pagamento semanal</strong><br>Seu dinheiro na conta toda semana, sem atrasos.</p>
      </div>
      <div class="vantagem">
        <img src="https://cdn-icons-png.flaticon.com/512/1995/1995514.png" alt="Suporte 24/7">
        <p><strong>Suporte 24/7</strong><br>Equipe disponível para te ajudar a qualquer momento.</p>
      </div>
    </div>
  </section>

  <section class="comparativo" id="ganhos">
    <h2>QUANTO VOCÊ PODE GANHAR?</h2>
    <div class="comparativo-container">
      <div class="plano">
        <h3>ENTREGADOR AUTÔNOMO</h3>
        <p><strong>R$ 7-12</strong> por entrega</p>
        <p><strong>+ Gorjetas</strong> dos clientes</p>
        <p><strong>Sem taxa fixa</strong> mensal</p>
        <hr style="margin:15px 0; border: 0; border-top: 1px solid #eee;">
        <ul>
          <li>Sem vínculo empregatício</li>
          <li>Sem mensalidade</li>
          <li>Sem cobrança de comissão</li>
        </ul>
      </div>
      <div class="plano green">
        <h3>VANTAGENS LET'S FOOD</h3>
        <p><strong>Pagamento semanal</strong> garantido</p>
        <p><strong>Suporte 24/7</strong> para entregadores</p>
        <p><strong>Área de descanso</strong> em parceria</p>
        <hr style="margin:15px 0; border: 0; border-top: 1px solid #eee;">
        <ul>
          <li>App fácil de usar</li>
          <li>Roteiro inteligente de entregas</li>
          <li>Seguro de acidentes</li>
          <li>Treinamento gratuito</li>
          <li>Bonificações por desempenho</li>
        </ul>
      </div>
    </div>
    <p class="footer-text">Ganhe mais fazendo parte da nossa equipe!</p>
  </section>
  
  

  <section id="faq" class="faq-section" style="background: #fff; padding: 80px 0;">
    <div class="container" style="max-width: 1000px; margin: 0 auto; padding: 0 20px; display: flex; flex-direction: column; align-items: center;">
      <div class="section-header" style="text-align: center; margin-bottom: 50px; width: 100%;">
        <h2 style="font-size: 2.5rem; color: #333; margin-bottom: 15px; font-weight: 600; letter-spacing: -0.5px;">
          Perguntas Frequentes
        </h2>
        <p style="font-size: 1.1rem; color: #666; max-width: 700px; margin: 15px auto 0; line-height: 1.6;">
          Encontre respostas para as dúvidas mais comuns sobre ser um entregador Let's Food
        </p>
      </div>
      
      <div class="faq-container">
        <div class="faq-item">
          <button class="faq-question">
            Como faço para me cadastrar como entregador?
            <span class="faq-icon">+</span>
          </button>
          <div class="faq-answer">
            <div class="faq-answer-inner">
              É simples! Basta clicar no botão "Quero ser Entregador" e preencher o formulário com seus dados. Nossa equipe entrará em contato em até 48 horas para concluir seu cadastro.
            </div>
          </div>
        </div>

        <div class="faq-item">
          <button class="faq-question">
            Quanto posso ganhar como entregador?
            <span class="faq-icon">+</span>
          </button>
          <div class="faq-answer">
            <div class="faq-answer-inner">
              Os ganhos variam conforme o volume de entregas realizadas. Em média, nossos entregadores ganham entre R$ 7 e R$ 12 por entrega, além das gorjetas dos clientes. Quanto mais você trabalha, mais você pode ganhar!
            </div>
          </div>
        </div>

        <div class="faq-item">
          <button class="faq-question">
            Posso escolher meus horários de trabalho?
            <span class="faq-icon">+</span>
          </button>
          <div class="faq-answer">
            <div class="faq-answer-inner">
              Sim! Você é quem define seus horários de trabalho. Pode trabalhar no horário que preferir, nos dias que quiser. Você é o dono do seu próprio tempo!
            </div>
          </div>
        </div>

        <div class="faq-item">
          <button class="faq-question">
            Como e quando recebo meus pagamentos?
            <span class="faq-icon">+</span>
          </button>
          <div class="faq-answer">
            <div class="faq-answer-inner">
              Os pagamentos são realizados semanalmente, sempre às quartas-feiras, diretamente na sua conta bancária. O valor é creditado automaticamente, sem burocracia.
            </div>
          </div>
        </div>

        <div class="faq-item">
          <button class="faq-question">
            Preciso ter veículo próprio?
            <span class="faq-icon">+</span>
          </button>
          <div class="faq-answer">
            <div class="faq-answer-inner">
              Sim, é necessário ter um veículo próprio (moto, bicicleta ou carro) em boas condições de uso. Também é necessário ter CNH (para motoristas) e documentos do veículo em dia.
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>

  <style>
    .faq-section {
      padding: 80px 0;
      background: #fff;
    }
    
    .container {
      max-width: 1000px;
      margin: 0 auto;
      padding: 0 20px;
    }
    
    .section-header {
      text-align: center;
      margin-bottom: 50px;
    }
    
    .section-header h2 {
      font-size: 2.5rem;
      color: #333;
      font-weight: 600;
      margin-bottom: 15px;
      letter-spacing: -0.5px;
    }
    
    .section-header p {
      font-size: 1.1rem;
      color: #666;
      max-width: 700px;
      margin: 15px auto 0;
      line-height: 1.6;
    }
    
    .faq-container {
      max-width: 800px;
      width: 100%;
      margin: 0 auto;
    }
    
    .faq-item {
      margin-bottom: 15px;
      border: 1px solid #e0e0e0;
      border-radius: 8px;
      overflow: hidden;
      background: #fff;
      box-shadow: 0 2px 15px rgba(0,0,0,0.05);
      transition: all 0.3s ease;
    }
    
    .faq-item:hover {
      box-shadow: 0 5px 20px rgba(0,0,0,0.08);
    }
    
    .faq-question {
      width: 100%;
      padding: 20px 25px;
      border: none;
      background: transparent;
      text-align: left;
      font-size: 1.1rem;
      font-weight: 500;
      color: #333;
      cursor: pointer;
      display: flex;
      justify-content: space-between;
      align-items: center;
      transition: all 0.2s ease;
    }
    
    .faq-question:hover {
      background-color: #f9f9f9;
    }
    
    .faq-icon {
      font-size: 1.5rem;
      color: #666;
      transition: all 0.3s ease;
    }
    
    .faq-answer {
      max-height: 0;
      overflow: hidden;
      transition: max-height 0.3s ease-out;
      background: #fff;
    }
    
    .faq-answer-inner {
      padding: 0 25px 25px;
      color: #555;
      line-height: 1.7;
      font-size: 1rem;
    }
    
    .faq-item.active .faq-question {
      background-color: #f9f9f9;
    }
    
    .faq-item.active .faq-icon {
      transform: rotate(45deg);
      color: #333;
    }
    
    .faq-item.active .faq-answer {
      max-height: 500px;
    }
    
    @media (max-width: 768px) {
      .faq-section {
        padding: 50px 0;
      }
      
      .section-header h2 {
        font-size: 2rem;
      }
      
      .section-header p {
        font-size: 1rem;
        padding: 0 10px;
      }
      
      .faq-question {
        padding: 18px 20px;
        font-size: 1rem;
      }
      
      .faq-answer-inner {
        padding: 0 20px 20px;
        font-size: 0.95rem;
      }
    }
  </style>
  
  <footer>
    © 2025 Let's Food - Todos os direitos reservados
  </footer>

  <script>
    // FAQ Toggle Functionality
    document.addEventListener('DOMContentLoaded', function() {
      const faqSection = document.querySelector('.faq-section');
      
      // Only run if FAQ section exists on the page
      if (faqSection) {
        const faqItems = document.querySelectorAll('.faq-item');
        
        faqItems.forEach(item => {
          const question = item.querySelector('.faq-question');
          
          if (question) {
            question.addEventListener('click', () => {
              // Close all other items
              faqItems.forEach(otherItem => {
                if (otherItem !== item) {
                  otherItem.classList.remove('active');
                }
              });
              
              // Toggle current item
              item.classList.toggle('active');
            });
          }
        });
      }
    });
  </script>

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
