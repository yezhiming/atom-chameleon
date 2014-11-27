module.exports = function(grunt) {

	grunt.initConfig({

		//claen the dist before copy & compile files
		clean: {
			dist: ['dist/'],
			vendor: ['vendor/'],
			frameworks: ['butterfly/', 'bootstrap/', 'ratchet']
		},

		bower: {
			install: {
				options: {
					production: true,
					targetDir: 'vendor',
					layout: 'byComponent',
					install: true,
					verbose: true,
					cleanTargetDir: true,
					cleanBowerDir: true
				}
			}
		},

		copy: {
			frameworks: {
				files: [
					{expand: true, cwd: 'vendor/butterfly/', src: ['**'], dest: 'butterfly'},
					{expand: true, cwd: 'vendor/bootstrap/', src: ['**'], dest: 'bootstrap'},
					{expand: true, cwd: 'vendor/ratchet/', src: ['**'], dest: 'ratchet'}
				]
			}
		}
	});

	grunt.loadNpmTasks('grunt-bower-task');
	grunt.loadNpmTasks('grunt-contrib-stylus');
	grunt.loadNpmTasks('grunt-contrib-requirejs');
	grunt.loadNpmTasks('grunt-contrib-copy');
	grunt.loadNpmTasks('grunt-contrib-clean');
	grunt.loadNpmTasks('grunt-contrib-concat');
	grunt.loadNpmTasks('grunt-contrib-uglify');
	grunt.loadNpmTasks('grunt-contrib-jshint');

	grunt.registerTask('build', ['clean:dist']);

	grunt.registerTask('install', ['clean:vendor', 'bower:install', 'copy:frameworks', 'clean:vendor']);

	grunt.registerTask('default', ['build']);

	grunt.registerTask('configure-production', ['']);
};
