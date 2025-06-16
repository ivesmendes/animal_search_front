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

// ===== FUNÇÕES PARA ABA "ANIMAIS ACHADOS" =====

// Carrega pedidos de animais encontrados
function carregarAchados() {
    const btnRefresh = document.querySelector('#tab-achados .btn-refresh');
    const listaAchados = document.getElementById('lista-achados');
    
    if (btnRefresh) {
        btnRefresh.classList.add('loading');
    }

    listaAchados.innerHTML = '<div class="empty-state"><div class="empty-state-icon">🔍</div><div class="empty-state-text">Carregando solicitações...</div><div class="empty-state-subtext">Aguarde enquanto buscamos as comparações pendentes</div></div>';

    db.collection('achados_pendentes')
        .orderBy('data_envio', 'desc')
        .get()
        .then((querySnapshot) => {
            if (btnRefresh) {
                btnRefresh.classList.remove('loading');
            }

            listaAchados.innerHTML = '';
            
            if (querySnapshot.empty) {
                listaAchados.innerHTML = `
                    <div class="empty-state">
                        <div class="empty-state-icon">✅</div>
                        <div class="empty-state-text">Nenhuma solicitação pendente</div>
                        <div class="empty-state-subtext">Todas as comparações foram processadas</div>
                    </div>
                `;
                atualizarContador('achados', 0);
                return;
            }

            atualizarContador('achados', querySnapshot.size);

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
                        <button class="btn btn-confirmar confirmar-achado">Confirmar Match</button>
                        <button class="btn btn-ignorar ignorar-achado">Não é o Mesmo</button>
                    </div>
                `;

                // Eventos botões
                pedido.querySelector('.confirmar-achado').onclick = () => confirmarAchado(doc.id, dados.animal_id);
                pedido.querySelector('.ignorar-achado').onclick = () => ignorarAchado(doc.id);

                listaAchados.appendChild(pedido);
                
                // Marcar como novo por 10 segundos
                setTimeout(() => {
                    pedido.classList.remove('novo');
                }, 10000);
            });
        })
        .catch((error) => {
            console.error("Erro ao carregar achados:", error);
            
            if (btnRefresh) {
                btnRefresh.classList.remove('loading');
            }
            
            listaAchados.innerHTML = `
                <div class="empty-state">
                    <div class="empty-state-icon">❌</div>
                    <div class="empty-state-text">Erro ao carregar solicitações</div>
                    <div class="empty-state-subtext">Tente recarregar clicando no botão "Atualizar"</div>
                </div>
            `;
            atualizarContador('achados', 0);
        });
}

// Função Confirmar Achado (remove o animal original e o pedido)
function confirmarAchado(pedidoId, animalId) {
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
                    carregarAchados();
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

// Função Ignorar Achado (remove só o pedido pendente)
function ignorarAchado(pedidoId) {
    if (!confirm("Confirmar que NÃO é o mesmo animal? Isso manterá o anúncio original ativo.")) return;

    const botao = event.target;
    const originalText = botao.innerHTML;
    botao.innerHTML = '<div class="loading"></div>';
    botao.disabled = true;

    db.collection('achados_pendentes').doc(pedidoId).delete()
        .then(() => {
            alert("❌ Solicitação rejeitada. O anúncio original permanece ativo.");
            carregarAchados();
        })
        .catch((error) => {
            console.error("Erro ao ignorar:", error);
            alert("Erro ao rejeitar: " + error.message);
            botao.innerHTML = originalText;
            botao.disabled = false;
        });
}

// ===== FUNÇÕES PARA ABA "POSSÍVEL NOVA LOCALIZAÇÃO" =====

// Carrega pedidos de possível nova localização
function carregarLocalizacao() {
    const btnRefresh = document.querySelector('#tab-localizacao .btn-refresh');
    const listaLocalizacao = document.getElementById('lista-localizacao');
    
    if (btnRefresh) {
        btnRefresh.classList.add('loading');
    }

    listaLocalizacao.innerHTML = '<div class="empty-state"><div class="empty-state-icon">📍</div><div class="empty-state-text">Carregando solicitações...</div><div class="empty-state-subtext">Aguarde enquanto buscamos as comparações de localização</div></div>';

    // Usando a estrutura real dos dados
    db.collection('duplicatas_pendentes')
        .get()
        .then((querySnapshot) => {
            if (btnRefresh) {
                btnRefresh.classList.remove('loading');
            }

            listaLocalizacao.innerHTML = '';
            
            if (querySnapshot.empty) {
                listaLocalizacao.innerHTML = `
                    <div class="empty-state">
                        <div class="empty-state-icon">✅</div>
                        <div class="empty-state-text">Nenhuma solicitação pendente</div>
                        <div class="empty-state-subtext">Não há comparações de localização para revisar</div>
                    </div>
                `;
                atualizarContador('localizacao', 0);
                return;
            }

            atualizarContador('localizacao', querySnapshot.size);

            querySnapshot.forEach((doc) => {
                const dados = doc.data();
                console.log("Dados do documento:", dados); // Para debug

                // Adaptando para a estrutura real dos dados
                const existingId = dados.existingId || 'N/A';
                const newData = dados.newData || {};
                
                // Buscar dados do animal existente
                db.collection('animais_perdidos').doc(existingId).get()
                    .then((existingDoc) => {
                        let imagemAntiga = 'https://via.placeholder.com/300x300?text=Imagem+não+encontrada';
                        
                        if (existingDoc.exists) {
                            const existingData = existingDoc.data();
                            imagemAntiga = existingData.imagem_url || imagemAntiga;
                        }

                        const pedido = document.createElement('div');
                        pedido.className = 'pedido localizacao novo';

                        pedido.innerHTML = `
                            <div class="pedido-header">
                                <div class="animal-id">Possível Duplicata: ${existingId}</div>
                                <div class="condicao localizacao">Tipo: ${newData.tipo || 'Não informado'} | Cor: ${newData.cor || 'Não informada'}</div>
                            </div>
                            
                            <div class="comparacao-fotos">
                                <div class="foto-container">
                                    <div class="foto-label localizacao-antiga">Animal Existente</div>
                                    <img src="${imagemAntiga}" alt="Animal Existente" class="pedido-imagem">
                                </div>
                                <div class="foto-container">
                                    <div class="foto-label localizacao-nova">Novo Registro</div>
                                    <img src="${newData.imagem_url || 'https://via.placeholder.com/300x300?text=Sem+imagem'}" alt="Novo Registro" class="pedido-imagem">
                                </div>
                            </div>
                            
                            <div class="acoes">
                                <button class="btn btn-atualizar confirmar-localizacao">Manter Novo</button>
                                <button class="btn btn-ignorar ignorar-localizacao">Manter Existente</button>
                            </div>
                        `;

                        // Eventos botões
                        pedido.querySelector('.confirmar-localizacao').onclick = () => confirmarLocalizacao(doc.id, existingId, newData);
                        pedido.querySelector('.ignorar-localizacao').onclick = () => ignorarLocalizacao(doc.id, newData);

                        listaLocalizacao.appendChild(pedido);
                        
                        // Marcar como novo por 10 segundos
                        setTimeout(() => {
                            pedido.classList.remove('novo');
                        }, 10000);
                    })
                    .catch((error) => {
                        console.error("Erro ao buscar animal existente:", error);
                    });
            });
        })
        .catch((error) => {
            console.error("Erro ao carregar localização:", error);
            
            if (btnRefresh) {
                btnRefresh.classList.remove('loading');
            }
            
            listaLocalizacao.innerHTML = `
                <div class="empty-state">
                    <div class="empty-state-icon">❌</div>
                    <div class="empty-state-text">Erro ao carregar solicitações</div>
                    <div class="empty-state-subtext">Tente recarregar clicando no botão "Atualizar"</div>
                </div>
            `;
            atualizarContador('localizacao', 0);
        });
}

// Função Confirmar Nova Localização (adiciona o novo e remove o antigo)
function confirmarLocalizacao(pedidoId, animalIdAntigo, newData) {
    if (!confirm("Confirmar que deve manter o novo registro? Isso removerá o registro anterior.")) return;

    const botao = event.target;
    const originalText = botao.innerHTML;
    botao.innerHTML = '<div class="loading"></div>';
    botao.disabled = true;

    // Primeiro, adicionar o novo animal na coleção
    db.collection('animais_perdidos').add(newData)
        .then((docRef) => {
            console.log("Novo animal adicionado com ID: ", docRef.id);
            
            // Depois de adicionar o novo, apagar o animal antigo
            db.collection('animais_perdidos').doc(animalIdAntigo).delete()
                .then(() => {
                    console.log("Animal antigo removido com ID: ", animalIdAntigo);
                    
                    // Por último, remover o pedido pendente
                    db.collection('duplicatas_pendentes').doc(pedidoId).delete()
                        .then(() => {
                            alert("📍 Novo registro adicionado e registro anterior removido com sucesso!");
                            carregarLocalizacao();
                        })
                        .catch((error) => {
                            console.error("Erro ao remover pedido de localização:", error);
                            alert("Novo animal foi adicionado, mas houve erro ao finalizar: " + error.message);
                            botao.innerHTML = originalText;
                            botao.disabled = false;
                        });
                })
                .catch((error) => {
                    console.error("Erro ao remover animal antigo:", error);
                    alert("Novo animal foi adicionado, mas erro ao remover o antigo: " + error.message);
                    botao.innerHTML = originalText;
                    botao.disabled = false;
                });
        })
        .catch((error) => {
            console.error("Erro ao adicionar novo animal:", error);
            alert("Erro ao adicionar novo registro: " + error.message);
            botao.innerHTML = originalText;
            botao.disabled = false;
        });
}

// Função Ignorar Nova Localização (remove apenas o pedido pendente, mantém ambos os animais)
function ignorarLocalizacao(pedidoId, newData) {
    if (!confirm("Confirmar que deve manter o registro anterior? Isso manterá apenas o registro existente.")) return;

    const botao = event.target;
    const originalText = botao.innerHTML;
    botao.innerHTML = '<div class="loading"></div>';
    botao.disabled = true;

    // Apenas remove o pedido pendente, mantendo o animal existente
    // O novo animal (newData) não foi adicionado ainda, então não precisa ser removido
    db.collection('duplicatas_pendentes').doc(pedidoId).delete()
        .then(() => {
            alert("📍 Registro anterior mantido. Novo registro descartado.");
            carregarLocalizacao();
        })
        .catch((error) => {
            console.error("Erro ao remover pedido:", error);
            alert("Erro ao finalizar processo: " + error.message);
            botao.innerHTML = originalText;
            botao.disabled = false;
        });
}

// ===== FUNÇÕES GERAIS =====

// Função para carregar pedidos (compatibilidade com código anterior)
function carregarPedidos() {
    carregarAchados();
}

// Função confirmar (compatibilidade com código anterior)
function confirmar(pedidoId, animalId) {
    confirmarAchado(pedidoId, animalId);
}

// Função ignorar (compatibilidade com código anterior)  
function ignorar(pedidoId) {
    ignorarAchado(pedidoId);
}

// Inicializar - carrega a primeira aba
carregarAchados();