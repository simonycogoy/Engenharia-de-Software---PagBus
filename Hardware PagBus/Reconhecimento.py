import cv2

#QR Codes válidos
QRCODES_VALIDOS = [
    "JOÃO VICTOR",
    "JOÃO PEDRO",
    "SIMONY"
]

class ReconhecimentoQRCode:
    def __init__(self):
        # Abre a câmera padrão do notebook
        self.camera = cv2.VideoCapture(0)

        # Cria o detector de QR Code do OpenCV
        self.detector_qr = cv2.QRCodeDetector()

    def ler_qrcode(self):
        sucesso, frame = self.camera.read()

        if not sucesso:
            return None

        conteudo_qr, pontos, _ = self.detector_qr.detectAndDecode(frame)

        if conteudo_qr:
            print("QR Code lido:", conteudo_qr)

            if conteudo_qr in QRCODES_VALIDOS:
                return "valido"
            else:
                return "invalido"

        return None

    def fechar_camera(self):
        self.camera.release()