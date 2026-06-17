import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/styles.dart';

class LoginChoiceScreen extends StatelessWidget {
  const LoginChoiceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Imagem de fundo
          Image.asset(
            'assets/image/teladelogin.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.error, size: 50, color: Color(0xFFF4870C)),
                ),
              );
            }
          ),

          // ConteÃºdo
          SafeArea(
            child: Column(
              children: [
                // BotÃ£o de voltar
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                ),

                const Spacer(),

                // Container branco com os botÃµes
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 30),

                      // BotÃµes de login e cadastro
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // BotÃ£o "JÃ¡ tenho uma conta"
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => Get.toNamed(
                                    RouteHelper.getSignInRoute('login-choice')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFF4870C),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'JÃ¡ tenho uma conta',
                                  style: robotoMedium.copyWith(fontSize: 16),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // BotÃ£o "Criar nova conta"
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () =>
                                    Get.toNamed(RouteHelper.getSignUpRoute()),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Color(0xFFF4870C),
                                  side: BorderSide(color: Color(0xFFF4870C)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Criar nova conta',
                                  style: robotoMedium.copyWith(fontSize: 16),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Texto "Acessar com"
                            Text(
                              'Acessar com',
                              style: robotoRegular.copyWith(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 15),

                            // BotÃµes de login social
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Google
                                InkWell(
                                  onTap: () {
                                    // Implementar login com Google
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 5,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      'assets/image/google.png',
                                      height: 30,
                                      width: 30,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 20),

                                // Facebook
                                InkWell(
                                  onTap: () {
                                    // Implementar login com Facebook
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 5,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      'assets/image/social_facebook.png',
                                      height: 30,
                                      width: 30,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
