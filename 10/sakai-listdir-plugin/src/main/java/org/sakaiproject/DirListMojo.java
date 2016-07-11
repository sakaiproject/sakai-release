package org.sakaiproject;

/*
 * Copyright 2001-2005 The Apache Software Foundation.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import org.apache.maven.plugin.AbstractMojo;
import org.apache.maven.plugin.MojoExecutionException;
import org.apache.maven.project.MavenProject;
import org.apache.maven.artifact.Artifact;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.*;

/**
 * Goal which lists all directores artifacts are in
 *
 * @goal list-dirs
 * 
 * @phase verify
 */
public class DirListMojo
    extends AbstractMojo
{
    /**
     * Location of the file.
     * @parameter expression="${project.build.directory}"
     * @required
     */
    private File outputDirectory;

	/**
     * Location of the file.
     * @parameter expression="${project.basedir}"
     * @required
     */
	private File basedir;

	/**
	 * Session root
	 * @parameter expression="${session.executionRootDirectory}"
	 * @required
	 */
	private File executionRoot;

    /**
     * @parameter default-value="${project}"
     * @required
     * @readonly
     */
    MavenProject project;

    public void execute()
        throws MojoExecutionException
    {
        Collection<Artifact> artifacts = new ArrayList<Artifact>();
        artifacts.add(project.getArtifact());
        artifacts.addAll(project.getAttachedArtifacts());

		String basePath = basedir.getAbsolutePath();
		String rootPath = executionRoot.getAbsolutePath();
		//absPath
		String absPath = "";
		if (!basePath.equals(rootPath)) {
			absPath = basePath.substring(rootPath.length()+1,basePath.length());
		}

//		System.out.println(rootPath);
//		System.out.println(basePath);
//		System.out.println(basePath.indexOf(rootPath));

        for (Artifact artifact : artifacts) {
            System.out.println(artifact + ":::" + basePath + ":::" + absPath);
        }
    }
}
