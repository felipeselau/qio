String authErrorMessage(String code) {
  switch (code) {
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
      return 'E-mail ou senha incorretos.';
    case 'invalid-email':
      return 'E-mail inválido.';
    case 'email-already-in-use':
      return 'Já existe uma conta com este e-mail.';
    case 'weak-password':
      return 'Senha fraca. Use pelo menos 6 caracteres.';
    case 'user-disabled':
      return 'Esta conta foi desativada.';
    case 'too-many-requests':
      return 'Muitas tentativas. Aguarde alguns minutos e tente de novo.';
    case 'network-request-failed':
      return 'Sem conexão. Verifique a internet e tente de novo.';
    default:
      return 'Não foi possível entrar. Tente novamente.';
  }
}
