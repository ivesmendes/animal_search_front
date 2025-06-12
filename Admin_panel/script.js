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
    listaPedidos.innerHTML = '';

    db.collection('achados_pendentes')
        .orderBy('data_envio', 'desc')
        .get()
        .then((querySnapshot) => {
            querySnapshot.forEach((doc) => {
                const dados = doc.data();

                const pedido = document.createElement('div');
                pedido.className = 'pedido';

                pedido.innerHTML = `
                    <div>
                        <strong>ID Animal:</strong> ${dados.animal_id}<br>
                        <strong>Condição:</strong> ${dados.animal_condicao || 'não informada'}
                    </div>
                    <img src="${dados.imagem_url_antiga}" alt="Imagem Antiga">
                    <img src="${dados.imagem_url_nova}" alt="Imagem Nova">
                    <div class="acoes">
                        <button class="confirmar">Confirmar</button>
                        <button class="ignorar">Ignorar</button>
                    </div>
                `;

                // Eventos botões
                pedido.querySelector('.confirmar').onclick = () => confirmar(doc.id, dados.animal_id);
                pedido.querySelector('.ignorar').onclick = () => ignorar(doc.id);

                listaPedidos.appendChild(pedido);
            });
        });
}

// Função Confirmar (remove o animal original e o pedido)
function confirmar(pedidoId, animalId) {
    if (!confirm("Deseja realmente confirmar essa solicitação?")) return;

    // Apagar animal original
    db.collection('animais_perdidos').doc(animalId).delete()
        .then(() => {
            // Remover pedido pendente
            db.collection('achados_pendentes').doc(pedidoId).delete()
                .then(() => {
                    alert("Solicitação confirmada e animal removido.");
                    carregarPedidos();
                });
        })
        .catch((error) => alert("Erro ao confirmar: " + error));
}

// Função Ignorar (remove só o pedido pendente)
function ignorar(pedidoId) {
    if (!confirm("Deseja ignorar essa solicitação?")) return;

    db.collection('achados_pendentes').doc(pedidoId).delete()
        .then(() => {
            alert("Solicitação ignorada e removida.");
            carregarPedidos();
        })
        .catch((error) => alert("Erro ao ignorar: " + error));
}

// Inicializar lista
carregarPedidos();
