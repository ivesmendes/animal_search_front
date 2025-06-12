// Substitua pelas suas credenciais Firebase
const firebaseConfig = {
  apiKey: "AIzaSyDB1t5Es7IpxsnJzcIQoOBP8iM1vg2JESA",
  authDomain: "animalsearch-d7828.firebaseapp.com",
  projectId: "animalsearch-d7828",
  storageBucket: "animalsearch-d7828.appspot.com",
  messagingSenderId: "827444107597",
  appId: "1:827444107597:web:c32975f20a20636a243f04"
};

firebase.initializeApp(firebaseConfig);
const db = firebase.firestore();

const listaPedidos = document.getElementById('lista-pedidos');

// Carrega pedidos pendentes
function carregarPedidos() {
    // Adicionar efeito visual ao botão de refresh
    const btnRefresh = document.querySelector('.btn-refresh');
    if (btnRefresh) {
        btnRefresh.classList.add('loading');
    }

    listaPedidos.innerHTML = '<div class="empty-state"><div class="empty-state-icon">🔍</div><div class="empty-state-text">Carregando solicitações...</div><div class="empty-state-subtext">Aguarde enquanto buscamos as comparações pendentes</div></div>';

    db.collection('achados_pendentes')
        .orderBy('data_envio', 'desc')
        .get()
        .then((querySnapshot) => {
            // Remover efeito loading do botão
            if (btnRefresh) {
                btnRefresh.classList.remove('loading');
            }

            listaPedidos.innerHTML = '';
            
            if (querySnapshot.empty) {
                listaPedidos.innerHTML = `
                    <div class="empty-state">
                        <div class="empty-state-icon">✅</div>
                        <div class="empty-state-text">Nenhuma solicitação pendente</div>
                        <div class="empty-state-subtext">Todas as comparações foram processadas</div>
                    </div>
                `;
                return;
            }

            querySnapshot.forEach((doc) => {
                const dados = doc.data();

                const pedido = document.createElement('div');
                pedido.className = 'pedido novo';

                pedido.innerHTML = `
                    <div class="pedido-header">
                        <div class="animal-id">ID do Animal: ${dados.animal_id}</div>
                        <div class="condicao">Condição: ${dados.condicao || 'Não informada'}</div>
                    </div>
                    
                    <div class="comparacao-fotos">
                        <div class="foto-container">
                            <div class="foto-label antiga">Foto Original (Anúncio)</div>
                            <img src="${dados.imagem_url_antiga}" alt="Foto Original do Anúncio" class="pedido-imagem">
                        </div>
                        <div class="foto-container">
                            <div class="foto-label nova">Foto Enviada (Encontrado)</div>
                            <img src="${dados.imagem_url_nova}" alt="Foto do Animal Encontrado" class="pedido-imagem">
                        </div>
                    </div>
                    
                    <div class="acoes">
                        <button class="btn btn-confirmar confirmar">Confirmar Match</button>
                        <button class="btn btn-ignorar ignorar">Não é o Mesmo</button>
                    </div>
                `;

                // Eventos botões
                pedido.querySelector('.confirmar').onclick = () => confirmar(doc.id, dados.animal_id);
                pedido.querySelector('.ignorar').onclick = () => ignorar(doc.id);

                listaPedidos.appendChild(pedido);
                
                // Marcar como novo por 10 segundos
                setTimeout(() => {
                    pedido.classList.remove('novo');
                }, 10000);
            });
        })
        .catch((error) => {
            console.error("Erro ao carregar pedidos:", error);
            
            // Remover efeito loading do botão em caso de erro
            if (btnRefresh) {
                btnRefresh.classList.remove('loading');
            }
            
            listaPedidos.innerHTML = `
                <div class="empty-state">
                    <div class="empty-state-icon">❌</div>
                    <div class="empty-state-text">Erro ao carregar solicitações</div>
                    <div class="empty-state-subtext">Tente recarregar clicando no botão "Atualizar"</div>
                </div>
            `;
        });
}

// Função Confirmar (remove o animal original e o pedido)
function confirmar(pedidoId, animalId) {
    if (!confirm("Confirmar que é o mesmo animal? Isso removerá o anúncio original do banco de dados.")) return;

    const botao = event.target;
    const originalText = botao.innerHTML;
    botao.innerHTML = '<div class="loading"></div>';
    botao.disabled = true;

    // Apagar animal original
    db.collection('animais_perdidos').doc(animalId).delete()
        .then(() => {
            // Remover pedido pendente
            db.collection('achados_pendentes').doc(pedidoId).delete()
                .then(() => {
                    alert("✅ Match confirmado! Animal removido do banco de dados.");
                    carregarPedidos();
                })
                .catch((error) => {
                    console.error("Erro ao remover pedido:", error);
                    alert("Erro ao finalizar processo: " + error.message);
                    botao.innerHTML = originalText;
                    botao.disabled = false;
                });
        })
        .catch((error) => {
            console.error("Erro ao remover animal:", error);
            alert("Erro ao confirmar: " + error.message);
            botao.innerHTML = originalText;
            botao.disabled = false;
        });
}

// Função Ignorar (remove só o pedido pendente)
function ignorar(pedidoId) {
    if (!confirm("Confirmar que NÃO é o mesmo animal? Isso manterá o anúncio original ativo.")) return;

    const botao = event.target;
    const originalText = botao.innerHTML;
    botao.innerHTML = '<div class="loading"></div>';
    botao.disabled = true;

    db.collection('achados_pendentes').doc(pedidoId).delete()
        .then(() => {
            alert("❌ Solicitação rejeitada. O anúncio original permanece ativo.");
            carregarPedidos();
        })
        .catch((error) => {
            console.error("Erro ao ignorar:", error);
            alert("Erro ao rejeitar: " + error.message);
            botao.innerHTML = originalText;
            botao.disabled = false;
        });
}

// Inicializar lista
carregarPedidos();