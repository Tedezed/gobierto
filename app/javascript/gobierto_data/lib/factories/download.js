import axios from 'axios';

// Data-endpoint factory to get/post/put/delete API data
export const DownloadFilesFactoryMixin = {
  methods: {
    getFiles(url, name) {
      return axios
        .get(url, { responseType: 'blob' })
        .then(response => {
          const blob = new Blob([response.data], { type: 'text/plain' });
          const link = document.createElement('a');
          link.href = URL.createObjectURL(blob);
          link.download = name;
          link.click();
          URL.revokeObjectURL(link.href);
        })
        .catch(console.error);
    }
  }
};
