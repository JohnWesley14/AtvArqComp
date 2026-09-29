# Trabalho de Introdução à Arquitetura de Computadores - PIC16F84A

**Instituição:** Universidade Federal do Maranhão (UFMA)  
**Docente:** Prof. Denivaldo Lopes  
**Semestre:** 2026.2  

## Descrição do Projeto
Este repositório contém as soluções práticas (em linguagem C) desenvolvidas para a 1ª avaliação da disciplina. Os programas foram concebidos para o microcontrolador **PIC16F84A**, utilizando o ambiente **MPLAB X IDE** (compilador XC8) e validados no simulador **PICSimLab**.

## Estrutura do Repositório
O repositório está dividido em dois projetos independentes do MPLAB X:

* **`Questao1.X/`**: Código-fonte e binários referentes à Questão 1.
* **`Questao3.X/`**: Código-fonte e binários referentes à Questão 3.

No interior de cada projeto existe uma pasta `WorkspacePicSimulator/` contendo os ficheiros de workspace (`.pzw`), que já incluem a placa pré-configurada e o firmware carregado para facilitar a validação.

## Questões Implementadas

### Questão 1 (Sensor e Sinal Quadrado)
O sistema verifica continuamente o sensor A através do pino RA1. 
* Se o sensor retornar `1`, o valor `0x72` é enviado pela porta B. 
* Caso contrário, é enviado o valor `0x81`. 
* Em simultâneo, o sistema gera um sinal quadrado com uma frequência de 4 Hz no pino RA0 (utilizando um clock de 4 MHz).

### Questão 3 (Seleção Prioritária de Pátios)
Sistema que seleciona prioritariamente o preenchimento de uma correia transportadora a partir de quatro pátios (A, B, C e D), utilizando os pinos RA1 a RA4 como entradas e RB0 a RB3 como saídas.
* **Prioridade 1 (Maior):** Pátio A (RA1 -> RB0)
* **Prioridade 2:** Pátio B (RA2 -> RB1)
* **Prioridade 3:** Pátio C (RA3 -> RB2)
* **Prioridade 4 (Menor):** Pátio D (RA4 -> RB3)

## Como Simular
Para testar o funcionamento sem necessidade de configurar o hardware manualmente no simulador:

1. Instale o [PICSimLab](https://lcgamboa.github.io/picsimlab/).
2. No menu principal do PICSimLab, vá a **File** > **Load Workspace**.
3. Navegue até à pasta do projeto desejado (`Questao1.X` ou `Questao3.X`) e entre na subpasta `WorkspacePicSimulator`.
4. Selecione o ficheiro `.pzw` (por exemplo, `Questao3.pzw`). O simulador carregará automaticamente a placa correta, o microcontrolador a 4 MHz e o ficheiro `.hex` correspondente.
5. Utilize os botões interativos da placa correspondentes à Porta A para validar as lógicas descritas acima.

## Como Compilar
Caso deseje alterar o código fonte (`main.c`):
1. Abra o **MPLAB X IDE**.
2. Vá a **File** > **Open Project** e selecione a pasta `Questao1.X` ou `Questao3.X`.
3. Clique em **Clean and Build** (ícone do martelo com a vassoura). O novo ficheiro `.hex` será gerado na pasta `dist/default/production/`.