
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/session/session_view_model.dart';
import '../view_models/login_view_model.dart';

/*
 * Schermata di accesso a Meevy.
 *
 * Raccoglie le credenziali e delega il login
 * al LoginViewModel.
 */
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Invia le credenziali e conferma la sessione se il login riesce.
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final success = await context.read<LoginViewModel>().login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      context.read<SessionViewModel>().onLoginSucceeded();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Consumer<LoginViewModel>(
                builder: (context, login, _) {
                  final warning =
                      context.watch<SessionViewModel>().logoutWarning;

                  return Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Meevy',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text('Accedi al tuo spazio di studio'),
                        const SizedBox(height: 32),

                        TextFormField(
                          controller: _emailController,
                          enabled: !login.isLoading,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Inserisci la tua email';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passwordController,
                          enabled: !login.isLoading,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Inserisci la password';
                            }
                            return null;
                          },
                        ),

                        if (warning != null) ...[
                          const SizedBox(height: 16),
                          Text(warning),
                        ],

                        if (login.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            login.errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        FilledButton(
                          onPressed: login.isLoading ? null : _login,
                          child: login.isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                              : const Text('Accedi'),
                        ),
                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: login.isLoading
                              ? null
                              : () {
                            context.read<SessionViewModel>().enterGuestMode();
                          },
                          child: const Text('Continua come ospite'),
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
