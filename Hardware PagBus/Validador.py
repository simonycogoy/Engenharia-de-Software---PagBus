import tkinter as tk
from datetime import datetime
from Reconhecimento import ReconhecimentoQRCode
import pygame
from pathlib import Path
from PIL import Image, ImageTk

pygame.mixer.init()

som_valido = pygame.mixer.Sound("bip.wav")
som_invalido = pygame.mixer.Sound("bip.wav")

# TAMANHO DA TELA

LARGURA_JANELA = 1920
ALTURA_JANELA = 1080

janela = tk.Tk()
janela.title("Validador PagBus")
janela.geometry(f"{LARGURA_JANELA}x{ALTURA_JANELA}")
janela.configure(bg="#000000")
janela.resizable(False, False)

canvas = tk.Canvas(janela, width=LARGURA_JANELA, height=ALTURA_JANELA, bg="#000000", highlightthickness=0)

canvas.pack()

BASE_DIR = Path(__file__).resolve().parent

empresa_selecionada = None
catraca_iniciada = False
linha_selecionada = None

imagens_tk = {}

#VALIDADOR

# muda o tamanho geral do validador
LARGURA_VALIDADOR = 1920
ALTURA_VALIDADOR = 1080

# Centraliza o validador na janela
X_VALIDADOR = (LARGURA_JANELA - LARGURA_VALIDADOR) // 2
Y_VALIDADOR = (ALTURA_JANELA - ALTURA_VALIDADOR) // 2

# Corpo preto do validador
canvas.create_rectangle( X_VALIDADOR, Y_VALIDADOR, X_VALIDADOR + LARGURA_VALIDADOR, Y_VALIDADOR + ALTURA_VALIDADOR, fill="black", outline="black")

#NOME PAGBUS

# nome em cima do validador
canvas.create_text(X_VALIDADOR + LARGURA_VALIDADOR // 2, Y_VALIDADOR + 120, text="PagBus", fill="#f2f7ff", font=("Arial", 70, "bold"))

#TELA BRANCA

# Tamanho da tela branca
LARGURA_TELA = 1280
ALTURA_TELA = 540

# Centraliza a tela dentro do validador
X_TELA = X_VALIDADOR + (LARGURA_VALIDADOR - LARGURA_TELA) // 2
Y_TELA = Y_VALIDADOR + 230

canvas.create_rectangle(
    X_TELA,
    Y_TELA,
    X_TELA + LARGURA_TELA,
    Y_TELA + ALTURA_TELA,
    fill="#1F7A3D",
    outline="#f2f7ff",
    width=4
)

texto_principal = canvas.create_text(
    X_TELA + LARGURA_TELA // 2,
    Y_TELA + 220,
    text="APROXIME\nO QR CODE",
    fill="#000000",
    font=("Silkscreen", 58, "bold"),
    justify="center"
)

texto_emoji = canvas.create_text(
    X_TELA + LARGURA_TELA // 2,
    Y_TELA + 350,
    text="",
    fill="#000000",
    font=("Noto Color Emoji", 46)
)

texto_detalhes = canvas.create_text(
    X_TELA + LARGURA_TELA // 2,
    Y_TELA + 415,
    text="",
    fill="#000000",
    font=("Arial", 26),
    justify="center"
)

texto_horario = canvas.create_text(
    X_TELA + LARGURA_TELA // 2,
    Y_TELA + 495,
    text="",
    fill="#000000",
    font=("Silkscreen", 16),
    justify="center",
    width=LARGURA_TELA - 40
)


# LEDS
LARGURA_LED = 90
ALTURA_LED = 45

Y_LED = Y_TELA + ALTURA_TELA + 125

QUANTIDADE_LEDS = 3
ESPACO_ENTRE_LEDS = 250

LARGURA_TOTAL_LEDS = (QUANTIDADE_LEDS * LARGURA_LED) + ((QUANTIDADE_LEDS - 1) * ESPACO_ENTRE_LEDS)

X_INICIAL_LEDS = X_VALIDADOR + (LARGURA_VALIDADOR - LARGURA_TOTAL_LEDS) // 2

leds = []

for i in range(QUANTIDADE_LEDS):
    x_led = X_INICIAL_LEDS + i * (LARGURA_LED + ESPACO_ENTRE_LEDS)

    led = canvas.create_rectangle(x_led, Y_LED, x_led + LARGURA_LED, Y_LED + ALTURA_LED, fill="#cfcfcf", outline="#888888", width=3)

    leds.append(led)

#RECONHECIMENTO QRCODE

reconhecimento = ReconhecimentoQRCode()

em_processamento = False
aguardando_remover_qrcode = False
frames_sem_qrcode = 0
FRAMES_PARA_CONFIRMAR_REMOCAO = 10

#FUNÇÕES DA CATRACA

def mudar_cor_leds(cor):
    for led in leds:
        canvas.itemconfig(led, fill=cor)

def bip():
    som_invalido.play()

def tres_bips():
    som_invalido.play()
    janela.after(300, som_invalido.play)
    janela.after(600, som_invalido.play)

def resetar_tela():
    global em_processamento
    global aguardando_remover_qrcode
    global frames_sem_qrcode

    mudar_cor_leds("#cfcfcf")

    canvas.coords(texto_principal, X_TELA + LARGURA_TELA // 2, Y_TELA + 220)
    canvas.coords(texto_emoji, X_TELA + LARGURA_TELA // 2, Y_TELA + 350)
    canvas.coords(texto_detalhes, X_TELA + LARGURA_TELA // 2, Y_TELA + 415)

    canvas.itemconfig(
        texto_principal,
        text="APROXIME\nO QR CODE",
        fill="#000000",
        font=("Silkscreen", 58, "bold")
    )

    canvas.itemconfig(
        texto_emoji,
        text="",
        font=("Noto Color Emoji", 46)
    )

    canvas.itemconfig(
        texto_detalhes,
        text="",
        font=("Arial", 26)
    )

    em_processamento = False
    aguardando_remover_qrcode = True
    frames_sem_qrcode = 0

def mostrar_qrcode_valido(resultado):
    mudar_cor_leds("green")

    nome = resultado.get("nome", "USUÁRIO")
    saldo = resultado.get("saldo", 0)

    canvas.coords(texto_principal, X_TELA + LARGURA_TELA // 2, Y_TELA + 190)

    canvas.itemconfig(
        texto_principal,
        text=f"PASSAGEM\nLIBERADA\n{nome}",
        fill="#000000",
        font=("Silkscreen", 34, "bold")
    )

    canvas.itemconfig(
        texto_emoji,
        text="✅",
        font=("Noto Color Emoji", 46)
    )

    canvas.itemconfig(
        texto_detalhes,
        text=f"Saldo: R$ {saldo:.2f}",
        fill="#000000",
        font=("Arial", 28)
    )

    bip()

    janela.after(3000, resetar_tela)

def mostrar_qrcode_invalido(resultado):
    mudar_cor_leds("red")

    saldo = resultado.get("saldo", 0)
    motivo = resultado.get("motivo", "QR Code inválido")

    # sobe a mensagem PASSAGEM BLOQUEADA
    canvas.coords(
        texto_principal,
        X_TELA + LARGURA_TELA // 2,
        Y_TELA + 165
    )

    # sobe o X vermelho
    canvas.coords(
        texto_emoji,
        X_TELA + LARGURA_TELA // 2,
        Y_TELA + 295
    )

    canvas.itemconfig(
        texto_principal,
        text="PASSAGEM\nBLOQUEADA",
        fill="#000000",
        font=("Silkscreen", 44, "bold")
    )

    canvas.itemconfig(
        texto_emoji,
        text="❌",
        font=("Noto Color Emoji", 46)
    )

    canvas.itemconfig(
        texto_detalhes,
        text=f"{motivo}\nSaldo: R$ {saldo:.2f}",
        fill="#000000",
        font=("Arial", 26)
    )

    tres_bips()

    janela.after(3000, resetar_tela)

# HORARIO
def atualizar_horario():
    #hora atual
    hora_atual = datetime.now().strftime("%H:%M:%S")
    
    #texto da linha e hora
    canvas.itemconfig(
        texto_horario,
        text=f"{empresa_selecionada}   |   {linha_selecionada}      {hora_atual}"
    )

    #att a cada 1seg
    janela.after(1000, atualizar_horario)

#LOOP PARA LER QR CODES
def verificar_qrcode():
    global em_processamento
    global aguardando_remover_qrcode
    global frames_sem_qrcode

    if aguardando_remover_qrcode:
        if reconhecimento.tem_qrcode_na_camera():
            frames_sem_qrcode = 0
        else:
            frames_sem_qrcode += 1

            if frames_sem_qrcode >= FRAMES_PARA_CONFIRMAR_REMOCAO:
                aguardando_remover_qrcode = False
                frames_sem_qrcode = 0

        janela.after(100, verificar_qrcode)
        return

    if em_processamento:
        janela.after(100, verificar_qrcode)
        return

    resultado = reconhecimento.ler_qrcode()

    if resultado is not None:
        status = resultado.get("status")

        if status == "valido":
            em_processamento = True
            mostrar_qrcode_valido(resultado)

        elif status == "invalido":
            em_processamento = True
            mostrar_qrcode_invalido(resultado)

    janela.after(100, verificar_qrcode)


def carregar_logo(nome_arquivo, largura=150, altura=150):
    caminho = BASE_DIR / nome_arquivo

    imagem = Image.open(caminho).convert("RGBA")

    # Remove bordas transparentes grandes da imagem
    bbox = imagem.getbbox()
    if bbox:
        imagem = imagem.crop(bbox)

    imagem.thumbnail((largura, altura), Image.LANCZOS)

    return ImageTk.PhotoImage(imagem)


def desenhar_fundo_empresas():
    canvas.create_rectangle(
        0, 0,
        LARGURA_JANELA, ALTURA_JANELA,
        fill="#000000",
        outline="",
        tags="tela_empresa"
    )

    canvas.create_text(
        LARGURA_JANELA // 2,
        110,
        text="PagBus",
        fill="#f2f7ff",
        font=("Arial", 72, "bold"),
        tags="tela_empresa"
    )

    canvas.create_text(
        LARGURA_JANELA // 2,
        185,
        text="Escolha a empresa de ônibus",
        fill="#f2f7ff",
        font=("Arial", 30, "bold"),
        tags="tela_empresa"
    )

    # Painel verde parecido com a tela da catraca
    canvas.create_rectangle(
        LARGURA_JANELA // 2 - 520,
        270,
        LARGURA_JANELA // 2 + 520,
        760,
        fill="#1F7A3D",
        outline="#f2f7ff",
        width=4,
        tags="tela_empresa"
    )


def criar_card_empresa(x, y, nome, arquivo_logo, cor_borda, tag):
    largura_card = 300
    altura_card = 310

    # Card principal
    canvas.create_rectangle(
        x - largura_card // 2,
        y - altura_card // 2,
        x + largura_card // 2,
        y + altura_card // 2,
        fill="#000000",
        outline=cor_borda,
        width=5,
        tags=("tela_empresa", tag)
    )

    imagens_tk[tag] = carregar_logo(arquivo_logo, 500, 500)

    canvas.create_image(
        x,
        y,
        image=imagens_tk[tag],
        tags=("tela_empresa", tag)
    )

    # Área invisível por cima para garantir que o clique funcione no card inteiro
    canvas.create_rectangle(
        x - largura_card // 2,
        y - altura_card // 2,
        x + largura_card // 2,
        y + altura_card // 2,
        fill="",
        outline="",
        tags=("tela_empresa", tag)
    )

    canvas.tag_bind(
        tag,
        "<Button-1>",
        lambda evento, empresa=nome: escolher_empresa(empresa)
    )

    canvas.tag_bind(
        tag,
        "<Enter>",
        lambda evento: canvas.config(cursor="hand2")
    )

    canvas.tag_bind(
        tag,
        "<Leave>",
        lambda evento: canvas.config(cursor="")
    )


def mostrar_tela_empresas():
    desenhar_fundo_empresas()

    criar_card_empresa(
        x=LARGURA_JANELA // 2 - 220,
        y=525,
        nome="StadtBus",
        arquivo_logo="logo_stadtbus.png",
        cor_borda="#1B9CFF",
        tag="opcao_stadtbus"
    )

    criar_card_empresa(
        x=LARGURA_JANELA // 2 + 220,
        y=525,
        nome="Anversa",
        arquivo_logo="logo_anversa.png",
        cor_borda="#FFD21A",
        tag="opcao_anversa"
    )


def escolher_empresa(nome_empresa):
    global empresa_selecionada
    global linha_selecionada
    global catraca_iniciada

    empresa_selecionada = nome_empresa
    reconhecimento.configurar_empresa(nome_empresa)

    if nome_empresa == "Anversa":
        mostrar_tela_linhas_anversa()
        return

    if nome_empresa == "StadtBus":
        mostrar_tela_linhas_stadtbus()
        return



LINHAS_ANVERSA = [
    "Ivo Ferronato (UNIPAMPA) x Arvorezinha",
    "São Domingos\nBairro Norte",
    "Madezatti\nVila Brasil",
    "Morgado Rosa\nAvenida Getúlio",
    "Cohab x Tiarajú / Aeroporto\nTiarajú / Aeroporto"
]

LINHAS_STADTBUS = [
    "Damé / Malafaia\nMalafaia",
    "União\nBairro Oeste",
    "Industrial\nCentro",
    "Camilo Gomes\nCentro",
    "Pedra Branca\nCentro"
]


def desenhar_fundo_linhas_stadtbus():
    canvas.create_rectangle(
        0, 0,
        LARGURA_JANELA, ALTURA_JANELA,
        fill="#000000",
        outline="",
        tags="tela_linhas"
    )

    canvas.create_text(
        LARGURA_JANELA // 2,
        110,
        text="LINHAS STADTBUS",
        fill="#f2f7ff",
        font=("Arial", 52, "bold"),
        tags="tela_linhas"
    )


def mostrar_tela_linhas_stadtbus():
    canvas.delete("tela_empresa")

    desenhar_fundo_linhas_stadtbus()

    criar_botao_linha(
        x=LARGURA_JANELA // 2 - 340,
        y=280,
        largura=560,
        altura=125,
        texto=LINHAS_STADTBUS[0],
        tag="linha_stadtbus_1"
    )

    criar_botao_linha(
        x=LARGURA_JANELA // 2 + 340,
        y=280,
        largura=560,
        altura=125,
        texto=LINHAS_STADTBUS[1],
        tag="linha_stadtbus_2"
    )

    criar_botao_linha(
        x=LARGURA_JANELA // 2 - 340,
        y=460,
        largura=560,
        altura=125,
        texto=LINHAS_STADTBUS[2],
        tag="linha_stadtbus_3"
    )

    criar_botao_linha(
        x=LARGURA_JANELA // 2 + 340,
        y=460,
        largura=560,
        altura=125,
        texto=LINHAS_STADTBUS[3],
        tag="linha_stadtbus_4"
    )

    criar_botao_linha(
        x=LARGURA_JANELA // 2,
        y=660,
        largura=560,
        altura=125,
        texto=LINHAS_STADTBUS[4],
        tag="linha_stadtbus_5"
    )


def desenhar_fundo_linhas_anversa():
    canvas.create_rectangle(
        0, 0,
        LARGURA_JANELA, ALTURA_JANELA,
        fill="#000000",
        outline="",
        tags="tela_linhas"
    )

    canvas.create_text(
        LARGURA_JANELA // 2,
        110,
        text="LINHAS ANVERSA",
        fill="#f2f7ff",
        font=("Arial", 52, "bold"),
        tags="tela_linhas"
    )


def criar_botao_linha(x, y, largura, altura, texto, tag):
    canvas.create_rectangle(
        x - largura // 2,
        y - altura // 2,
        x + largura // 2,
        y + altura // 2,
        fill="#000000",
        outline="#f2f7ff",
        width=4,
        tags=("tela_linhas", tag)
    )

    canvas.create_text(
        x,
        y,
        text=texto,
        fill="#f2f7ff",
        font=("Arial", 18, "bold"),
        justify="center",
        width=largura - 40,
        tags=("tela_linhas", tag)
    )

    canvas.tag_bind(
        tag,
        "<Button-1>",
        lambda evento, linha=texto: escolher_linha(linha)
    )

    canvas.tag_bind(
        tag,
        "<Enter>",
        lambda evento: canvas.config(cursor="hand2")
    )

    canvas.tag_bind(
        tag,
        "<Leave>",
        lambda evento: canvas.config(cursor="")
    )


def mostrar_tela_linhas_anversa():
    canvas.delete("tela_empresa")

    desenhar_fundo_linhas_anversa()

    criar_botao_linha(
        x=LARGURA_JANELA // 2 - 340,
        y=280,
        largura=560,
        altura=125,
        texto=LINHAS_ANVERSA[0],
        tag="linha_anversa_1"
    )

    criar_botao_linha(
        x=LARGURA_JANELA // 2 + 340,
        y=280,
        largura=560,
        altura=125,
        texto=LINHAS_ANVERSA[1],
        tag="linha_anversa_2"
    )

    criar_botao_linha(
        x=LARGURA_JANELA // 2 - 340,
        y=460,
        largura=560,
        altura=125,
        texto=LINHAS_ANVERSA[2],
        tag="linha_anversa_3"
    )

    criar_botao_linha(
        x=LARGURA_JANELA // 2 + 340,
        y=460,
        largura=560,
        altura=125,
        texto=LINHAS_ANVERSA[3],
        tag="linha_anversa_4"
    )

    criar_botao_linha(
        x=LARGURA_JANELA // 2,
        y=660,
        largura=560,
        altura=125,
        texto=LINHAS_ANVERSA[4],
        tag="linha_anversa_5"
    )


def escolher_linha(linha):
    global linha_selecionada
    global catraca_iniciada

    print("Linha escolhida:", linha)

    linha_selecionada = linha.replace("\n", " / ")

    reconhecimento.configurar_linha(linha_selecionada)

    canvas.delete("tela_linhas")

    if not catraca_iniciada:
        catraca_iniciada = True
        atualizar_horario()
        verificar_qrcode()


#FECHAR PROGRAMA
def fechar_programa():
    reconhecimento.fechar_camera()
    pygame.mixer.quit()
    janela.destroy()

janela.protocol("WM_DELETE_WINDOW", fechar_programa)

#INICIAR PROGRAMA
mostrar_tela_empresas()

janela.mainloop()