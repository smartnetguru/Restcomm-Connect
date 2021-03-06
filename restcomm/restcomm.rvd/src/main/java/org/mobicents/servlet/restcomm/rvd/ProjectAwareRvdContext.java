package org.mobicents.servlet.restcomm.rvd;

import javax.servlet.ServletContext;
import javax.servlet.http.HttpServletRequest;

import org.mobicents.servlet.restcomm.rvd.model.ProjectSettings;
import org.mobicents.servlet.restcomm.rvd.storage.FsProjectStorage;
import org.mobicents.servlet.restcomm.rvd.storage.exceptions.StorageEntityNotFound;
import org.mobicents.servlet.restcomm.rvd.storage.exceptions.StorageException;

public class ProjectAwareRvdContext extends RvdContext {

    private String projectName;
    private ProjectLogger projectLogger;
    private ProjectSettings projectSettings;

    public ProjectAwareRvdContext(String projectName, HttpServletRequest request, ServletContext servletContext) throws StorageException {
        super(request, servletContext);
        if (projectName == null)
            throw new IllegalArgumentException();
        setProjectName(projectName);
    }

    public ProjectAwareRvdContext(HttpServletRequest request, ServletContext servletContext) {
        super(request, servletContext);
    }

    public ProjectLogger getProjectLogger() {
        return projectLogger;
    }

    public ProjectSettings getProjectSettings() {
        return projectSettings;
    }

    public void setProjectName(String projectName) {
        this.projectName = projectName;
        if (projectName != null) {
            this.projectLogger = new ProjectLogger(projectName, getSettings(), getMarshaler());
            try {
                this.projectSettings = FsProjectStorage.loadProjectSettings(projectName, workspaceStorage);
            } catch (StorageEntityNotFound e) {
                this.projectSettings = ProjectSettings.createDefault();
            } catch (StorageException e) {
                throw new RuntimeException(e); // serious error
            }
        } else {
            this.projectLogger = null;
            this.projectSettings = null;
        }
    }

    public String getProjectName() {
        return projectName;
    }
}
