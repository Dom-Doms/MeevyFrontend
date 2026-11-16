
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/register_view_model.dart';

//Schermata di registrazione di Meevy.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controller utilizzati per leggere ciò che l'utente scrive.
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;

  // Verifica il form e richiede la registrazione.
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final success = await context.read<RegisterViewModel>().register(
      email: _emailController.text,
      password: _passwordController.text,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
    );

    if (!mounted) return;

    // Torna al login comunicando che la registrazione è riuscita.
    if (success) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Costruisce un campo con label, icona e bordo arrotondato.

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    const borderColor = Color(0xFFDDDFDD);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF202425),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFFA1A4A6),
              fontSize: 15,
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF737779),
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            enabledBorder: OutlineInputBorder(//Disegna i bordi arrotondati dei campi.
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: borderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: Color(0xFF4D8B67),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: Colors.redAccent,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( //Crea la base della schermata con lo sfondo chiaro.
      backgroundColor: const Color(0xFFFCFCFA),
      body: SafeArea( //	Evita che il contenuto finisca sotto la barra di stato e i controlli del telefono.
        child: SingleChildScrollView(//Permette di scorrere quando il form è più alto dello schermo o appare la tastiera.
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Consumer<RegisterViewModel>(
                builder: (context, register, _) {
                  return Form(
                    key: _formKey,
                    autovalidateMode:
                    AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                      children: [
                        // Logo presente nelle risorse di Meevy.
                        Center(
                          child: Container(
                            width: 92,
                            height: 92,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F7F3),
                              borderRadius:
                              BorderRadius.circular(26),
                            ),
                            child: Image.asset(
                              'assets/branding/meevy_icon.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'Registrazione',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E2223),
                          ),
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'Crea il tuo account e inizia il tuo '
                              'percorso verso una versione più '
                              'produttiva di te.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            color: Color(0xFF85888A),
                          ),
                        ),

                        const SizedBox(height: 34),

                        // Nome e cognome sono facoltativi nel backend.
                        _buildField(
                          label: 'Nome (facoltativo)',
                          hint: 'Inserisci il tuo nome',
                          controller: _firstNameController,
                          icon: Icons.person_outline,
                          enabled: !register.isLoading,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value != null &&
                                value.trim().length > 100) {
                              return 'Massimo 100 caratteri';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 17),

                        _buildField(
                          label: 'Cognome (facoltativo)',
                          hint: 'Inserisci il tuo cognome',
                          controller: _lastNameController,
                          icon: Icons.person_outline,
                          enabled: !register.isLoading,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value != null &&
                                value.trim().length > 100) {
                              return 'Massimo 100 caratteri';
                            }
                            return null;
                          },
                        ),

                        //Mostra un avviso quando nome e cognome sono entrambi vuoti.

                        ListenableBuilder(
                          listenable: Listenable.merge([
                            _firstNameController,
                            _lastNameController,
                          ]),
                          builder: (context, child) {
                            final noName = _firstNameController.text.trim().isEmpty &&
                                _lastNameController.text.trim().isEmpty;

                            if (!noName) {
                              return const SizedBox.shrink();
                            }

                            return const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 18,
                                    color: Color(0xFF85888A),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Non hai inserito nome e cognome. '
                                          'La tua email sarà il riferimento '
                                          'principale del tuo account.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF85888A),
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),


                        const SizedBox(height: 17),

                        _buildField(
                          label: 'Email',
                          hint: '',
                          controller: _emailController,
                          icon: Icons.mail_outline,
                          enabled: !register.isLoading,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            final email = value?.trim() ?? '';

                            if (email.isEmpty) {
                              return 'Inserisci la tua email';
                            }

                            final validEmail = RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            ).hasMatch(email);

                            if (!validEmail) {
                              return 'Inserisci un indirizzo email valido';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 17),

                        _buildField(
                          label: 'Password',
                          hint: 'Crea una password',
                          controller: _passwordController,
                          icon: Icons.lock_outline,
                          enabled: !register.isLoading,
                          obscureText: !_showPassword,
                          textInputAction: TextInputAction.next,
                          suffixIcon: IconButton(
                            tooltip: _showPassword
                                ? 'Nascondi password'
                                : 'Mostra password',
                            onPressed: () {
                              setState(() {
                                _showPassword = !_showPassword;
                              });
                            },
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Inserisci una password';
                            }

                            if (value.length < 8) {
                              return 'Servono almeno 8 caratteri';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 17),

                        _buildField(
                          label: 'Conferma password',
                          hint: 'Ripeti la password',
                          controller: _confirmPasswordController,
                          icon: Icons.lock_outline,
                          enabled: !register.isLoading,
                          obscureText: !_showConfirmPassword,
                          textInputAction: TextInputAction.done,
                          suffixIcon: IconButton(
                            tooltip: _showConfirmPassword
                                ? 'Nascondi conferma password'
                                : 'Mostra conferma password',
                            onPressed: () {
                              setState(() {
                                _showConfirmPassword =
                                !_showConfirmPassword;
                              });
                            },
                            icon: Icon(
                              _showConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Conferma la password';
                            }

                            if (value != _passwordController.text) {
                              return 'Le password non coincidono';
                            }

                            return null;
                          },
                        ),

                        // Messaggio d'errore proveniente dal ViewModel.
                        if (register.errorMessage != null) ...[
                          const SizedBox(height: 18),
                          Text(
                            register.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                            ),
                          ),
                        ],

                        const SizedBox(height: 28),

                        // Pulsante principale, scuro come nel prototipo.
                        SizedBox(
                          height: 56,
                          child: FilledButton(
                            onPressed: register.isLoading
                                ? null
                                : _register,
                            style: FilledButton.styleFrom(
                              backgroundColor:
                              const Color(0xFF232728),
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                            ),
                            child: register.isLoading
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Crea account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Icon(Icons.arrow_forward),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 27),

                        // Separatore con la scritta "oppure".
                        const Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Text(
                                'oppure',
                                style: TextStyle(
                                  color: Color(0xFF85888A),
                                ),
                              ),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),

                        const SizedBox(height: 20),

                        TextButton(
                          onPressed: register.isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Hai già un account?  ',
                                  style: TextStyle(
                                    color: Color(0xFF85888A),
                                  ),
                                ),
                                TextSpan(
                                  text: 'Torna al login',
                                  style: TextStyle(
                                    color: Color(0xFF202425),
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
