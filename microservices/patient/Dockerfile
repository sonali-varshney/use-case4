FROM node:20

# Set the working directory inside the container.
WORKDIR /usr/src/app

# Copy the entire project directory into the container's working directory.
COPY . .

# Expose the port your application listens on. For example, 3000.
EXPOSE 3000

# Specify the command to run when the container starts.
CMD [ "node", "patient-service.js" ]