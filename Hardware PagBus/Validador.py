import tkinter as tk
from datetime import datetime
from Reconhecimento import ReconhecimentoQRCode
import pygame

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
LARGURA_TELA = 720
ALTURA_TELA = 480

# Centraliza a tela dentro do validador
X_TELA = X_VALIDADOR + (LARGURA_VALIDADOR - LARGURA_TELA) // 2
Y_TELA = Y_VALIDADOR + 230

canvas.create_rectangle(X_TELA, Y_TELA, X_TELA + LARGURA_TELA, Y_TELA + ALTURA_TELA, fill="#1F7A3D", outline="#f2f7ff", width=4)

texto_principal = canvas.create_text(X_TELA + LARGURA_TELA // 2, Y_TELA + 200, text="APROXIME\nO QR CODE", fill="#000000", font=("Silkscreen", 58, "bold"), justify="center")
texto_emoji = canvas.create_text(X_TELA + LARGURA_TELA // 2, Y_TELA + 310, text="", fill="#000000", font=("Arial", 70))

texto_horario = canvas.create_text(X_TELA + LARGURA_TELA // 2, Y_TELA + 425, text="", fill="#000000", font=("Silkscreen", 20))


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

    mudar_cor_leds("#cfcfcf")

    canvas.itemconfig(texto_principal, text="APROXIME\nO QR CODE", fill="#000000")
    canvas.itemconfig(texto_emoji, text="")

    em_processamento = False
    aguardando_remover_qrcode = True

def mostrar_qrcode_valido():
    mudar_cor_leds("green")

    canvas.itemconfig(texto_principal, text="QR CODE\nVÁLIDO\n", fill="#000000")
    canvas.itemconfig(texto_emoji, text="✅", font=("Noto Color Emoji", 60))

    bip()

    janela.after(3000, resetar_tela)

def mostrar_qrcode_invalido():
    mudar_cor_leds("red")

    canvas.itemconfig(texto_principal, text="QR CODE\nINVÁLIDO\n", fill="#000000")
    canvas.itemconfig(texto_emoji, text="❌", font=("Noto Color Emoji", 60))

    tres_bips()

    janela.after(3000, resetar_tela)

# HORARIO
def atualizar_horario():
    #hora atual
    hora_atual = datetime.now().strftime("%H:%M:%S")
    
    #texto da linha e hora
    canvas.itemconfig(texto_horario, text=f"Linha: UNIPAMPA      {hora_atual}")

    #att a cada 1seg
    janela.after(1000, atualizar_horario)

#LOOP PARA LER QR CODES
def verificar_qrcode():
    global em_processamento
    global aguardando_remover_qrcode

    resultado = reconhecimento.ler_qrcode()

    # Se acabou de ler um QR Code, espera ele sair da câmera
    if aguardando_remover_qrcode:
        if resultado is None:
            aguardando_remover_qrcode = False

        janela.after(100, verificar_qrcode)
        return
    
    # Se está mostrando "válido" ou "inválido", não lê outro
    if em_processamento:
        janela.after(100, verificar_qrcode)
        return

    if resultado == "valido":
        em_processamento = True
        mostrar_qrcode_valido()

    elif resultado == "invalido":
        em_processamento = True
        mostrar_qrcode_invalido()

    janela.after(100, verificar_qrcode)

#FECHAR PROGRAMA
def fechar_programa():
    reconhecimento.fechar_camera()
    pygame.mixer.quit()
    janela.destroy()

janela.protocol("WM_DELETE_WINDOW", fechar_programa)

#INICIAR PROGRAMA
atualizar_horario()
verificar_qrcode()

janela.mainloop()