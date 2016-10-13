package org.daisy.dotify.impl.system.common;

import org.daisy.dotify.api.tasks.TaskGroupFactoryMakerService;
import org.daisy.dotify.api.tasks.TaskGroupSpecification;
import org.daisy.dotify.api.tasks.TaskSystem;
import org.daisy.dotify.api.tasks.TaskSystemFactory;
import org.daisy.dotify.api.tasks.TaskSystemFactoryException;
import org.daisy.dotify.impl.input.SPIHelper;

import aQute.bnd.annotation.component.Component;
import aQute.bnd.annotation.component.Reference;

/**
 * Provides a default task system factory for PEF, OBFL and text output.
 * 
 * @author Joel Håkansson
 */
@Component
public class DotifyTaskSystemFactory implements TaskSystemFactory {
	private TaskGroupFactoryMakerService imf;

	@Override
	public boolean supportsSpecification(String locale, String outputFormat) {
		for (TaskGroupSpecification spec : imf.listSupportedSpecifications()) {
			if (spec.getOutputFormat().equals(outputFormat) && locale.equalsIgnoreCase(spec.getLocale())) {
				return true;
			}
		}
		return false;
	}

	@Override
	public TaskSystem newTaskSystem(String locale, String outputFormat) throws TaskSystemFactoryException {
		if (supportsSpecification(locale, outputFormat)) {
			return new DotifyTaskSystem("Dotify Task System", outputFormat, locale, imf);
		}
		throw new TaskSystemFactoryException("Unsupported specification: " + locale + "/" + outputFormat);
	}

	@Reference
	public void setInputManagerFactory(TaskGroupFactoryMakerService service) {
		this.imf = service;
	}

	public void unsetInputManagerFactory(TaskGroupFactoryMakerService service) {
		this.imf = null;
	}

	@Override
	public void setCreatedWithSPI() {
		if (imf == null) {
			imf = SPIHelper.getInputManagerFactoryMakerService();
		}
	}

}
