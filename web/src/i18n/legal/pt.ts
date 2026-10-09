import type { LegalBundle } from './types';

const bundle: LegalBundle = {
  draftBanner:
    'Minuta técnica — revisar com o orientador/jurídico antes de publicação. Este texto não substitui parecer jurídico e não promete conformidade com a LGPD.',
  effectiveLabel: 'Vigência',
  effectivePlaceholder: '[data de vigência]',
  contactHeading: 'Canal de contato',
  contactIntro:
    'Para exercer seus direitos ou tirar dúvidas sobre seus dados, fale com o controlador (o estabelecimento que opera a fila):',
  contactMissing:
    'Canal de contato não configurado. Contate o estabelecimento onde você entrou na fila.',
  privacy: {
    title: 'Política de privacidade',
    sections: [
      {
        heading: '1. Quem é quem',
        paragraphs: [
          'Controlador: o estabelecimento que cria e opera a fila e decide por que e como seus dados são usados.',
          'Operador: o Qio, projeto acadêmico (TCC) que fornece a ferramenta e trata os dados em nome do estabelecimento, seguindo as instruções dele.',
        ],
      },
      {
        heading: '2. Quais dados tratamos',
        items: [
          'Nome (1 a 60 caracteres), informado por você ao entrar na fila.',
          'Telefone, opcional, no formato (00) 00000-0000, informado por você.',
          'Identificador anônimo de sessão (Firebase Authentication anônimo), criado automaticamente ao abrir a página da fila. Não está ligado a e-mail ou conta.',
          'Dados da senha: número da senha, situação (aguardando, chamado, atendido, não compareceu, saiu), horários de entrada e chamada, idioma e, se escolhida, a faixa de horário.',
          'Token de notificação push, opcional, somente se você tocar em "Ativar aviso".',
          'Pedido "Me avise quando abrir", opcional: token de push, idioma e data do pedido, ligados ao identificador anônimo de sessão, sem nome nem telefone.',
          'Avaliação (nota de 1 a 5 e comentário opcional) enviada após o atendimento.',
          'Estatísticas de uso do site (Google Analytics), apenas se configuradas pelo estabelecimento, sem coleta quando o navegador envia Do Not Track ou quando você desliga no rodapé.',
        ],
      },
      {
        heading: '3. Para que usamos',
        paragraphs: [
          'Organizar a fila, informar sua posição, chamar você quando chegar a vez e, se você ativar, avisar pelo celular. As estatísticas servem para melhorar o serviço.',
        ],
      },
      {
        heading: '4. Base legal',
        paragraphs: [
          'Execução do serviço que você pediu ao entrar na fila e consentimento do titular ao digitar os dados no formulário e ao ativar avisos ou estatísticas. A definição final da base legal cabe ao controlador e à revisão jurídica.',
        ],
      },
      {
        heading: '5. Com quem compartilhamos',
        paragraphs: [
          'O estabelecimento (dono e operadores da fila) vê nome e telefone dos participantes. Para hospedar e processar os dados, usamos Firebase/Google Cloud como suboperador (Authentication, Realtime Database, Firestore, Cloud Functions, Cloud Messaging, Hosting e Analytics). Os servidores podem ficar fora do Brasil.',
          'Não vendemos dados nem os usamos para publicidade.',
          'Outros participantes da fila veem apenas o número da senha e a situação, sem nome nem telefone.',
        ],
      },
      {
        heading: '6. Por quanto tempo guardamos',
        items: [
          'Entrada ativa na fila (nome, telefone, token de push): somente enquanto você está na fila; é removida ao ser atendido, ao sair ou quando a fila é apagada.',
          'Pedido "Me avise quando abrir" (token de push, idioma e data): até a fila abrir (apagado após o aviso), por no máximo 24 horas, até você cancelar ou até a fila ser apagada.',
          'Histórico de atendimentos do estabelecimento (nome, telefone, resultado e horários): prazo-alvo de 180 dias. A rotina automática de exclusão ainda depende de implementação.',
          'Avaliações: mantidas pelo estabelecimento até que ele as apague ou apague a fila.',
          'Registros de limite de tentativas (identificador anônimo e horários): técnicos, sem nome nem telefone.',
        ],
      },
      {
        heading: '7. Seus direitos',
        paragraphs: [
          'Você pode pedir ao controlador: confirmação de que tratamos seus dados e acesso a eles, correção de dados incorretos, eliminação de dados desnecessários ou tratados com base no consentimento, e informações sobre o compartilhamento. Também pode sair da fila a qualquer momento pela própria página, o que encerra o uso da entrada ativa.',
        ],
      },
      {
        heading: '8. Armazenamento local e cookies',
        items: [
          'localStorage do navegador: identificação da sua entrada na fila (qio:entries), avaliação pendente (qio:feedback), idioma (qio:lang), tema (qio:theme), aviso de instalação dispensado (qio:install-dismissed) e a escolha de não coletar estatísticas (qio:analytics-optout).',
          'O Firebase Authentication guarda o identificador anônimo de sessão no armazenamento do navegador.',
          'Se as estatísticas estiverem ativas, o Google Analytics pode gravar cookies. Você pode desligar pelo link no rodapé.',
          'Limpar os dados do site no navegador apaga tudo isso localmente.',
        ],
      },
      {
        heading: '9. Crianças',
        paragraphs: [
          'O serviço não é direcionado a menores de 12 anos. Para adolescentes e crianças, o tratamento deve ocorrer com o consentimento de um responsável, conforme orientação do controlador.',
        ],
      },
      {
        heading: '10. Segurança',
        paragraphs: [
          'Regras de acesso restringem a leitura de nome e telefone ao dono e aos operadores da fila, e a entrada na fila é validada em servidor com limite de tentativas. Nenhum sistema é totalmente seguro.',
        ],
      },
      {
        heading: '11. Alterações',
        paragraphs: [
          'Podemos atualizar esta política. A data de vigência indica a versão atual.',
        ],
      },
    ],
  },
  terms: {
    title: 'Termos de uso',
    sections: [
      {
        heading: '1. O serviço',
        paragraphs: [
          'O Qio permite entrar em uma fila presencial pelo navegador, sem instalar nada, e acompanhar sua posição. A fila é operada pelo estabelecimento, que decide quem é chamado e quando.',
        ],
      },
      {
        heading: '2. Projeto acadêmico',
        paragraphs: [
          'O Qio é um projeto acadêmico (TCC), oferecido como está, sem garantia de disponibilidade contínua. A estimativa de espera é aproximada.',
        ],
      },
      {
        heading: '3. Suas responsabilidades',
        items: [
          'Informar dados verdadeiros e que sejam seus.',
          'Não usar o serviço para abuso, automação ou para atrapalhar outras pessoas; há limite de tentativas de entrada.',
          'Acompanhar a página ou ativar avisos: o estabelecimento pode marcar não comparecimento se você não atender à chamada.',
        ],
      },
      {
        heading: '4. Responsabilidade do estabelecimento',
        paragraphs: [
          'O estabelecimento é responsável pelo atendimento, pela ordem da fila e pelo uso dos dados que coleta, conforme a política de privacidade.',
        ],
      },
      {
        heading: '5. Limitação de responsabilidade',
        paragraphs: [
          'Na medida permitida em lei, o Qio não responde por perdas decorrentes de indisponibilidade, atrasos de notificação ou decisões do estabelecimento. Este item está sujeito à revisão jurídica.',
        ],
      },
      {
        heading: '6. Privacidade',
        paragraphs: ['O tratamento de dados está descrito na política de privacidade.'],
      },
      {
        heading: '7. Alterações',
        paragraphs: [
          'Estes termos podem mudar. O uso após a mudança indica concordância com a versão vigente.',
        ],
      },
    ],
  },
};

export default bundle;
