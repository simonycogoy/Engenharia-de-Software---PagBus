import cv2
from firebase_admin import firestore
from firebase_config import db

VALOR_PASSAGEM = 4.50


class ReconhecimentoQRCode:

    def __init__(self):
        self.camera = cv2.VideoCapture(0)
        self.detector_qr = cv2.QRCodeDetector()

    def ler_conteudo_qrcode(self):
        sucesso, frame = self.camera.read()

        if not sucesso:
            return None

        conteudo_qr, pontos, _ = self.detector_qr.detectAndDecode(frame)

        if conteudo_qr:
            return conteudo_qr.strip()

        return None

    def tem_qrcode_na_camera(self):
        conteudo = self.ler_conteudo_qrcode()
        return conteudo is not None

    def validar_usuario_e_descontar_saldo(self, usuario_id):
        usuario_ref = db.collection("usuarios").document(usuario_id)
        transaction = db.transaction()

        @firestore.transactional
        def executar_transacao(transaction, usuario_ref, usuario_id):
            usuario_doc = usuario_ref.get(transaction=transaction)

            if not usuario_doc.exists:
                return {"status": "invalido", "motivo": "QR não cadastrado"}

            dados = usuario_doc.to_dict()

            nome = dados.get("nome", "USUÁRIO")
            saldo = dados.get("saldo", 0)
            ativo = dados.get("ativo", True)

            if not ativo:
                return {
                    "status": "invalido",
                    "motivo": "Conta inativa",
                    "nome": nome,
                }

            try:
                saldo = float(saldo)
            except:
                return {
                    "status": "invalido",
                    "motivo": "Saldo inválido",
                    "nome": nome,
                }

            if saldo < VALOR_PASSAGEM:
                return {
                    "status": "invalido",
                    "motivo": "Saldo insuficiente",
                    "nome": nome,
                    "saldo": saldo,
                }

            novo_saldo = round(saldo - VALOR_PASSAGEM, 2)

            # 1. Atualiza o saldo do usuário
            transaction.update(
                usuario_ref,
                {
                    "saldo": novo_saldo,
                    "ultimo_uso_catraca": firestore.SERVER_TIMESTAMP,
                },
            )

            # 2. Registra o histórico da passagem
            passagem_ref = usuario_ref.collection("passagens").document()
            linha_onibus = "UNIPAMPA"
            empresa_onibus = "Anversa"

            transaction.set(
                passagem_ref,
                {
                    "valor": VALOR_PASSAGEM,
                    "status": "aprovada",
                    "linha": list_onibus,
                    "data": firestore.SERVER_TIMESTAMP,
                    "empresa": empresa_onibus,
                },
            )

            # 3. 🔔 GERA A NOTIFICAÇÃO EM TEMPO REAL PARA O FLUTTER
            notificacao_ref = usuario_ref.collection("notificacoes").document()
            transaction.set(
                notificacao_ref,
                {
                    "id": notificacao_ref.id,
                    "titulo": "Embarque Confirmado! 🚌",
                    "mensagem": f"Você embarcou na linha {linha_onibus} ({empresa_onibus}). Tenha uma excelente viagem e boa jornada!",
                    "tipo": "line_info",
                    "linha_numero": "Nº 402",  # Prefixo do ônibus (opcional, pode ser dinâmico)
                    "lido": False,
                    "criadoEm": firestore.SERVER_TIMESTAMP,
                },
            )

            return {"status": "valido", "nome": nome, "saldo": novo_saldo}

        try:
            # CORREÇÃO: Passando o usuario_id exigido pela assinatura da função acima
            return executar_transacao(transaction, usuario_ref, usuario_id)

        except Exception as erro:
            print("Erro ao acessar Firebase:", erro)
            return {"status": "invalido", "motivo": "Erro no Firebase"}

    def ler_qrcode(self):
        usuario_id = self.ler_conteudo_qrcode()

        if not usuario_id:
            return None

        print("QR Code lido:", usuario_id)

        return self.validar_usuario_e_descontar_saldo(usuario_id)

    def fechar_camera(self):
        self.camera.release()
