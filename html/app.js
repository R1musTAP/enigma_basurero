const app = new Vue({
    el: '#app',
    data: {
        show: false,
        screen: 'main',
        progress: 0,
        completed: 0,
        total: 0,
        route: null
    },
    methods: {
        startSolo() {
            fetch(`https://${GetParentResourceName()}/startSolo`, {
                method: 'POST'
            });
        },
        startPartner() {
            fetch(`https://${GetParentResourceName()}/startPartner`, {
                method: 'POST'
            });
        },
        updateProgress(data) {
            this.completed = data.completed;
            this.total = data.total;
            this.progress = (data.completed / data.total) * 100;
        }
    }
});

window.addEventListener('message', (event) => {
    const data = event.data;
    
    switch(data.action) {
        case 'show':
            app.show = true;
            app.screen = 'main';
            break;
        case 'hide':
            app.show = false;
            break;
        case 'startRoute':
            app.screen = 'route';
            app.route = data.data.route;
            app.total = data.data.route.length;
            app.completed = 0;
            break;
        case 'updateProgress':
            app.updateProgress(data.data);
            break;
    }
});