'use strict';

const FIRST_NAMES = [
  'Ana', 'Beatriz', 'Bruno', 'Camila', 'Carlos', 'Carolina', 'Daniel', 'Daniela', 'Diego', 'Eduarda',
  'Eduardo', 'Elisa', 'Fábio', 'Fernanda', 'Felipe', 'Gabriel', 'Gabriela', 'Gustavo', 'Helena', 'Henrique',
  'Igor', 'Isabela', 'Jéssica', 'João', 'Joana', 'José', 'Juliana', 'Kauã', 'Larissa', 'Leandro',
  'Letícia', 'Lucas', 'Luana', 'Luiz', 'Marcelo', 'Márcia', 'Mariana', 'Mateus', 'Mônica', 'Natália',
  'Nicolas', 'Olívia', 'Paulo', 'Patrícia', 'Pedro', 'Rafael', 'Rafaela', 'Renata', 'Ricardo', 'Roberto',
  'Rodrigo', 'Sabrina', 'Samuel', 'Sandra', 'Sérgio', 'Sofia', 'Tatiane', 'Thiago', 'Valentina', 'Vanessa',
  'Vinícius', 'Vitória', 'William', 'Yasmin', 'Adriana', 'Alessandro', 'Bianca', 'Cláudia', 'Davi', 'Débora',
  'Érica', 'Flávia', 'Giovanna', 'Heitor', 'Ítalo', 'Jorge', 'Karina', 'Lívia', 'Miguel', 'Nathalia',
  'Otávio', 'Priscila', 'Raquel', 'Sílvia', 'Tereza', 'Ulisses', 'Vera', 'Wagner', 'Zilda', 'Antônio',
];

const SURNAMES = [
  'Silva', 'Santos', 'Oliveira', 'Souza', 'Rodrigues', 'Ferreira', 'Alves', 'Pereira', 'Lima', 'Gomes',
  'Costa', 'Ribeiro', 'Martins', 'Carvalho', 'Almeida', 'Lopes', 'Soares', 'Fernandes', 'Vieira', 'Barbosa',
  'Rocha', 'Dias', 'Nascimento', 'Andrade', 'Moreira', 'Nunes', 'Marques', 'Machado', 'Mendes', 'Freitas',
  'Cardoso', 'Ramos', 'Gonçalves', 'Santana', 'Teixeira', 'Araújo', 'Pinto', 'Correia', 'Cavalcanti', 'Monteiro',
  'Batista', 'Moraes', 'Duarte', 'Campos', 'Cunha', 'Borges', 'Reis', 'Azevedo', 'Farias', 'Medeiros',
];

const COMMENTS = {
  low: [
    'Esperei demais.',
    'Demorou muito para ser chamado.',
    'Fila parada, sem previsão.',
    'Atendimento lento.',
    'Perdi quase uma hora aqui.',
    'Poderiam ter mais atendentes.',
    'Chamaram e eu nem estava vendo o aviso.',
  ],
  mid: [
    'Ok, mas demorou um pouco.',
    'Atendimento normal.',
    'Esperava mais agilidade.',
    'Foi razoável.',
    'Resolveu, só a espera que pesou.',
  ],
  high: [
    'Muito bom!',
    'Rápido e prático.',
    'Adorei não ter que ficar em pé na fila.',
    'Atendimento excelente.',
    'Recomendo, a fila pelo celular ajuda muito.',
    'Equipe educada e eficiente.',
    'Tudo certo, super tranquilo.',
    'Aviso na hora certa, gostei.',
    'Nota 10.',
  ],
};

module.exports = { FIRST_NAMES, SURNAMES, COMMENTS };
