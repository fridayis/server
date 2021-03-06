(() => {
    // 项目管理service
    'use strict';
    let projectModule = angular.module('projectModule', []);

    function DomeProject($http, $util, $state, $domePublic, $domeModel, $q, $modal) {
        const ProjectService = function () {
            this.url = 'api/project';
            $domeModel.ServiceModel.call(this, this.url);
            this.getReadMe = (proId, branch) => $http.get(this.url + '/readme/' + proId + '/' + branch);
            this.getBuildList = (proId) => $http.get('/api/ci/build/' + proId);
            this.getBranches = (proId) => $http.get(this.url + '/branches/' + proId);
            this.getBranchesWithoutId = (codeId, codeManagerUserId, codeManager) => $http.get(this.url + '/branches/' + codeManager + '/' + codeId + '/' + codeManagerUserId);
            this.getTags = (proId) => $http.get(this.url + '/tags/' + proId);
            this.getTagsWithoutId = (codeId, codeManagerUserId, codeManager) => $http.get(this.url + '/tags/' + codeManager + '/' + codeId + '/' + codeManagerUserId);
            this.getGitLabInfo = () => $http.get(this.url + '/git/gitlabinfo');
            this.getBuildDockerfile = (proId, buildId) => $http.get('/api/ci/build/dockerfile/' + proId + '/' + buildId);
            this.previewDockerfile = (projectConfig) => $http.post('/api/ci/build/dockerfile', angular.toJson(projectConfig), {
                notIntercept: true
            });
            this.build = (buildInfo) => $http.post('/api/ci/build/start', angular.toJson(buildInfo), {
                notIntercept: true
            });
        };
        const projectService = new ProjectService();

        const buildProject = (proId, hasCodeInfo) => {
            const buildModalIns = $modal.open({
                animation: true,
                templateUrl: '/index/tpl/modal/buildModal/buildModal.html',
                controller: 'BuildModalCtr as vm',
                size: 'md',
                resolve: {
                    projectInfo: {
                        projectId: proId,
                        hasCodeInfo: hasCodeInfo
                    }
                }
            });
            return buildModalIns.result;
        };

        class ProjectImages {
            constructor() {
                this.imageInfo = {
                    compileIsPublic: 1,
                    runIsPublic: 1
                };
                this.selectedCompileImage = {};
                this.selectedRunImage = {};
                this.currentCompileList = [];
                this.currentRunList = [];
                this.projectImagesInfo = {
                    compilePublicImageList: [],
                    compilePrivateImageList: [],
                    runPublicImageList: [],
                    runPrivateImageList: []
                };
            }
            init(imagesInfo) {
                if (!imagesInfo)
                    imagesInfo = {};
                if (!imagesInfo.compilePublicImageList) {
                    imagesInfo.compilePublicImageList = [];
                }
                if (!imagesInfo.compilePrivateImageList) {
                    imagesInfo.compilePrivateImageList = [];
                }
                if (!imagesInfo.runPublicImageList) {
                    imagesInfo.runPublicImageList = [];
                }
                if (!imagesInfo.runPrivateImageList) {
                    imagesInfo.runPrivateImageList = [];
                }

                angular.forEach(imagesInfo, (imageList, imageListName) => {
                    for (let i = 0; i < imageList.length; i++) {
                        imageList[i].createDate = $util.getPageDate(imageList[i].createTime);
                        imageList[i].imageTxt = imageList[i].imageName;
                        if (imageList[i].imageTag) {
                            imageList[i].imageTxt += ':' + imageList[i].imageTag;
                        }
                    }
                });
                this.projectImagesInfo = imagesInfo;
                if (Object.keys(this.selectedCompileImage).length === 0) {
                    this.toggleIsPublicImage('compile');
                    this.toggleIsPublicImage('run');
                }
            }
            toggleIsPublicImage(imageType, isPublic) {
                    if (isPublic === undefined) {
                        isPublic = imageType == 'compile' ? this.imageInfo.compileIsPublic : this.imageInfo.runIsPublic;
                    }
                    if (imageType == 'compile') {
                        this.currentCompileList = isPublic === 1 ? this.projectImagesInfo.compilePublicImageList : this.projectImagesInfo.compilePrivateImageList;
                        this.toggleImage('compile', 0);
                    } else {
                        this.currentRunList = isPublic === 1 ? this.projectImagesInfo.runPublicImageList : this.projectImagesInfo.runPrivateImageList;
                        this.toggleImage('run', 0);
                    }
                }
                // @param imageType: 'compile(编译镜像)/'run'(运行镜像)
                // @param index: 切换到imageType镜像的index下标
            toggleImage(imageType, index) {
                    if (imageType === 'compile') {
                        this.selectedCompileImage = this.currentCompileList[index];
                    } else if (imageType === 'run') {
                        this.selectedRunImage = angular.copy(this.currentRunList[index]);
                    }
                }
                // 设置默认选择的镜像
            toggleSpecifiedImage(type, imgObj) {
                let imageTxt = '';
                if (imgObj) {
                    imageTxt = imgObj.imageName;
                    if (imgObj.imageTag) {
                        imageTxt += ':' + imgObj.imageTag;
                    }
                } else {
                    imgObj = {};
                }
                if (type == 'compile') {
                    this.selectedCompileImage = imgObj;
                    this.selectedCompileImage.imageTxt = imageTxt;
                    if (imgObj.registryType !== undefined) {
                        this.imageInfo.compileIsPublic = imgObj.registryType;
                    } else {
                        this.imageInfo.compileIsPublic = 1;
                    }
                    this.currentCompileList = imgObj.registryType === 1 ? this.projectImagesInfo.compilePublicImageList : this.projectImagesInfo.compilePrivateImageList;

                } else {
                    this.selectedRunImage = imgObj;
                    this.selectedRunImage.imageTxt = imageTxt;
                    if (imgObj.registryType !== undefined) {
                        this.imageInfo.runIsPublic = imgObj.registryType;
                    } else {
                        this.imageInfo.runIsPublic = 1;
                    }
                    this.currentRunList = imgObj.registryType === 1 ? this.projectImagesInfo.runPublicImageList : this.projectImagesInfo.runPrivateImageList;
                }
            }

        }

        class Project {
            constructor(initInfo) {
                this.config = {};
                // 提取公共config,保持view不变
                this.customConfig = {};
                this.isUseCustom = false;
                this.projectImagesIns = new ProjectImages();
                this.init(initInfo);
            }
            init(project) {
                let i = 0,
                    autoBuildInfo;
                if (!project) {
                    project = {};
                }
                this.customConfig = {};
                if (!project.dockerfileInfo) {
                    project.dockerfileInfo = {};
                }
                if (!project.dockerfileConfig) {
                    project.dockerfileConfig = {};
                }
                if (!project.userDefineDockerfile) {
                    this.customConfig = !project.exclusiveBuild ? project.dockerfileConfig : project.exclusiveBuild;
                }
                // 初始化 autoBuildInfo
                this.autoBuildInfo = angular.copy(project.autoBuildInfo);
                project.autoBuildInfo = (() => {
                    let autoBuildInfo = project.autoBuildInfo,
                        newAutoBuildInfo, branches;
                    if (!autoBuildInfo) {
                        return {
                            tag: 0,
                            master: false,
                            other: false,
                            branches: ''
                        };
                    }
                    branches = project.autoBuildInfo.branches;
                    newAutoBuildInfo = {
                        tag: autoBuildInfo.tag || 0,
                        master: false,
                        other: false,
                        branches: ''
                    };
                    if (branches) {
                        for (let i = 0; i < branches.length; i++) {
                            if (branches[i] == 'master') {
                                newAutoBuildInfo.master = true;
                                branches.splice(i, 1);
                                i--;
                            }
                        }
                        if (branches.length !== 0) {
                            newAutoBuildInfo.other = true;
                            newAutoBuildInfo.branches = branches.join(',');
                        }
                    }
                    return newAutoBuildInfo;

                })();


                project.confFiles = (() => {
                    let confFiles = project.confFiles,
                        newArr = [];
                    if (!confFiles || confFiles.length === 0) {
                        return [{
                            tplDir: '',
                            originDir: ''
                        }];
                    }
                    for (let key of Object.keys(confFiles)) {
                        newArr.push({
                            tplDir: key,
                            originDir: confFiles[key]
                        });
                    }
                    newArr.push({
                        tplDir: '',
                        originDir: ''
                    });
                    return newArr;
                })();
                this.isUseCustom = !!this.customConfig.customType;

                if (!project.envConfDefault) {
                    project.envConfDefault = [];
                }
                project.envConfDefault.push({
                    key: '',
                    value: '',
                    description: ''
                });

                this.customConfig.compileEnv = function () {
                    let compileEnv = this.customConfig.compileEnv;
                    if (!compileEnv) {
                        return [{
                            envName: '',
                            envValue: ''
                        }];
                    }
                    let compileEnvArr = compileEnv.split(',');
                    let newArr = compileEnvArr.map((item) => {
                        let sigEnv = item.split('=');
                        return {
                            envName: sigEnv[0],
                            envValue: sigEnv[1]
                        };
                    });
                    newArr.push({
                        envName: '',
                        envValue: ''
                    });
                    return newArr;
                }.bind(this)();

                this.customConfig.createdFileStoragePath = function () {
                    let createdFileStoragePath = this.customConfig.createdFileStoragePath;
                    if (!createdFileStoragePath || createdFileStoragePath.length === 0) {
                        return [{
                            name: ''
                        }];
                    }
                    let newArr = createdFileStoragePath.map((item) => {
                        return {
                            name: item
                        };
                    });
                    newArr.push({
                        name: ''
                    });
                    return newArr;
                }.bind(this)();

                this.config = project;
                this.creatorDraft = {};
                project = null;
            }
            resetConfig() {
                this.config.dockerfileConfig = null;
                this.config.dockerfileInfo = null;
                this.config.exclusiveBuild = null;
                this.config.dockerfileInfo = null;
                this.config.confFiles = null;
                this.config.envConfDefault = null;
                this.config.autoBuildInfo = this.autoBuildInfo;
                this.init(this.config);
            }
            deleteArrItem(item, index) {
                this.config[item].splice(index, 1);
            }
            deleteCompileEnv(index) {
                this.customConfig.compileEnv.splice(index, 1);
            }
            deleteCreatedFileStoragePath(index) {
                this.customConfig.createdFileStoragePath.splice(index, 1);
            }
            addEnvConfDefault() {
                this.config.envConfDefault.push({
                    key: '',
                    value: '',
                    description: ''
                });
            }
            toggleBaseImage(imageName, imageTag, imageRegistry) {
                this.customConfig.baseImageName = imageName;
                this.customConfig.baseImageTag = imageTag;
                this.customConfig.baseImageRegistry = imageRegistry;
            }
            addCreatedFileStoragePath() {
                this.customConfig.createdFileStoragePath.push({
                    name: ''
                });
            }
            addCompileEnv() {
                this.customConfig.compileEnv.push({
                    envName: '',
                    envValue: ''
                });
            }
            addConfFiles() {
                this.config.confFiles.push({
                    tplDir: '',
                    originDir: ''
                });
            }
            modify() {
                let createProject = this._formartProject();
                console.log(createProject);
                return $http.put('/api/project', angular.toJson(createProject));
            }
            delete() {
                let defered = $q.defer();
                $domePublic.openDelete().then(() => {
                    projectService.deleteData(this.config.id).then(() => {
                        $domePublic.openPrompt('删除成功！');
                        defered.resolve();
                    }, (res) => {
                        $domePublic.openWarning({
                            title: '删除失败！',
                            msg: res.data.resultMsg
                        });
                        defered.reject('fail');
                    });
                }, () => {
                    defered.reject('dismiss');
                });
                return defered.promise;
            }
            getDockerfile() {

                let openDockerfile = () => {
                    $modal.open({
                        animation: true,
                        templateUrl: '/index/tpl/modal/dockerfileModal/dockerfileModal.html',
                        controller: 'DockerfileModalCtr as vm',
                        size: 'md',
                        resolve: {
                            project: this
                        }
                    });
                };

                if (this.config.userDefineDockerfile) {

                    const useDockerfileModalIns = $modal.open({
                        templateUrl: '/index/tpl/modal/branchCheckModal/branchCheckModal.html',
                        controller: 'BranchCheckModalCtr as vm',
                        size: 'md',
                        resolve: {
                            codeInfo: () => this.config.codeInfo,
                            projectId: () => this.config.id
                        }
                    });

                    useDockerfileModalIns.result.then((branchInfo) => {
                        this.config.dockerfileInfo.branch = this.config.dockerfileInfo.tag = null;
                        this.config.dockerfileInfo[branchInfo.type] = branchInfo.value;
                        openDockerfile();
                    });
                } else {
                    openDockerfile();
                }
            }
            _formartCreateProject(projectInfo, creatorDraft) {
                return {
                    project: projectInfo,
                    creatorDraft: creatorDraft
                };
            }
            _formartProject() {
                let formartProject = {},
                    compileEnvStr = '',
                    createdFileStoragePathArr = [],
                    project = angular.copy(this.config),
                    customConfig = angular.copy(this.customConfig);

                project.envConfDefault = (() => {
                    let newArr = [];
                    for (let sigEnvConfDefault of project.envConfDefault) {
                        if (sigEnvConfDefault.key && sigEnvConfDefault.value) {
                            newArr.push({
                                key: sigEnvConfDefault.key,
                                value: sigEnvConfDefault.value,
                                description: sigEnvConfDefault.description
                            });
                        }
                    }
                    return newArr;
                })();

                project.autoBuildInfo = (() => {
                    let autoBuildInfo = project.autoBuildInfo,
                        newAutoBuildInfo;
                    if (!project.codeInfo || !autoBuildInfo.other && !autoBuildInfo.master && !autoBuildInfo.tag) {
                        return null;
                    }
                    newAutoBuildInfo = {
                        tag: autoBuildInfo.tag,
                        branches: []
                    };
                    if (autoBuildInfo.other) {
                        newAutoBuildInfo.branches = autoBuildInfo.branches.split(',');
                    }
                    if (autoBuildInfo.master) {
                        newAutoBuildInfo.branches.push('master');
                    }
                    return newAutoBuildInfo;
                })();

                if (project.userDefineDockerfile) {
                    formartProject.name = project.name;
                    formartProject.id = project.id;
                    if (project.codeInfo) {
                        formartProject.codeInfo = project.codeInfo;
                        formartProject.autoBuildInfo = project.autoBuildInfo;
                    }
                    formartProject.exclusiveBuild = null;
                    formartProject.userDefineDockerfile = project.userDefineDockerfile;
                    formartProject.dockerfileInfo = project.dockerfileInfo;
                    formartProject.authority = project.authority;
                    formartProject.envConfDefault = project.envConfDefault;
                } else {
                    if (project.dockerfileInfo) {
                        project.dockerfileInfo = null;
                    }
                    project.confFiles = (() => {
                        let newConfFiles = {};
                        for (let confFile of project.confFiles) {
                            if (confFile.tplDir && confFile.originDir) {
                                newConfFiles[confFile.tplDir] = confFile.originDir;
                            }
                        }
                        return newConfFiles;
                    })();

                    compileEnvStr = (() => {
                        let str = '',
                            strArr = [];
                        for (let env of customConfig.compileEnv) {
                            if (env.envName && env.envValue) {
                                strArr.push(env.envName + '=' + env.envValue);
                            }
                        }
                        return strArr.join(',');
                    })();

                    createdFileStoragePathArr = (() => {
                        let newArr = [];
                        for (let item of customConfig.createdFileStoragePath) {
                            if (item.name) {
                                newArr.push(item.name);
                            }
                        }
                        return newArr;
                    })();


                    if (this.isUseCustom) {
                        project.dockerfileConfig = null;
                        project.exclusiveBuild = {
                            customType: customConfig.customType,
                            compileImage: this.projectImagesIns.selectedCompileImage,
                            runImage: this.projectImagesIns.selectedRunImage,
                            codeStoragePath: customConfig.codeStoragePath,
                            compileEnv: compileEnvStr,
                            compileCmd: customConfig.compileCmd,
                            createdFileStoragePath: createdFileStoragePathArr,
                            workDir: customConfig.workDir,
                            user: customConfig.user,
                            runFileStoragePath: this.projectImagesIns.selectedRunImage.runFileStoragePath,
                            startCmd: this.projectImagesIns.selectedRunImage.startCommand
                        };
                        // 未初始化this.projectImagesIns.selectedCompileImage时
                        if (!this.projectImagesIns.selectedCompileImage.imageName) {
                            project.exclusiveBuild.compileImage = this.customConfig.compileImage;
                            project.exclusiveBuild.runImage = this.customConfig.runImage;
                            project.exclusiveBuild.runFileStoragePath = this.customConfig.runFileStoragePath;
                            project.exclusiveBuild.startCmd = this.customConfig.startCmd;
                        }
                    } else {
                        project.exclusiveBuild = null;
                        project.dockerfileConfig = {
                            baseImageName: customConfig.baseImageName,
                            baseImageTag: customConfig.baseImageTag,
                            baseImageRegistry: customConfig.baseImageRegistry,
                            installCmd: customConfig.installCmd,
                            codeStoragePath: customConfig.codeStoragePath,
                            compileEnv: compileEnvStr,
                            compileCmd: customConfig.compileCmd,
                            workDir: customConfig.workDir,
                            startCmd: customConfig.startCmd,
                            user: customConfig.user
                        };
                    }
                    formartProject = project;
                }
                return formartProject;
            }
            create() {
                let createProject = this._formartProject(),
                    creatorDraft = angular.copy(this.creatorDraft);
                console.log(createProject);
                return $http.post('/api/project', angular.toJson(this._formartCreateProject(createProject, creatorDraft)));
            }
        }

        const getInstance = $domeModel.instancesCreator({
            Project: Project,
            ProjectImages: ProjectImages
        });

        return {
            projectService: projectService,
            getInstance: getInstance,
            buildProject: buildProject
        };

    }
    DomeProject.$inject = ['$http', '$util', '$state', '$domePublic', '$domeModel', '$q', '$modal'];
    projectModule.factory('$domeProject', DomeProject);
    window.projectModule = projectModule;
})();